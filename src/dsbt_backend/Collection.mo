import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";
import Nat8 "mo:base/Nat8";
import Int "mo:base/Int";

import Types "./Types";
import Utils "./Utils";
shared actor class Collection(collectionOwner : Types.Account, init : Types.CollectionInitArgs) = Self {

  private stable let hub_canister_id = "lyp2p-oiaaa-aaaan-qedqq-cai";
  private stable var owner : Types.Account = collectionOwner;

  private stable var name : Text = init.name;
  private stable var symbol : Text = init.symbol;
  private stable var royalties : ?Nat16 = init.royalties;
  private stable var royaltyRecipient : ?Types.Account = init.royaltyRecipient;
  private stable var description : ?Text = init.description;
  private stable var image : ?Text = init.image;
  private stable var supplyCap : ?Nat = init.supplyCap;
  private stable var totalSupply : Nat = 0;
  private stable var transferSequentialIndex : Nat = 0;
  private stable var approvalSequentialIndex : Nat = 0;
  private stable var transactionSequentialIndex : Nat = 0;
  private stable var next_token_id : Nat = 0;

  // https://forum.dfinity.org/t/is-there-any-address-0-equivalent-at-dfinity-motoko/5445/3
  private var NULL_PRINCIPAL : Principal = Principal.fromText("aaaaa-aa");
  private var PERMITTED_DRIFT : Nat64 = 2 * 60 * 1_000_000_000; // 2 minutes in nanoseconds
  private var TX_WINDOW : Nat64 = 24 * 60 * 60 * 1_000_000_000; // 24 hours in nanoseconds

  private stable var tokens : Trie<Types.TokenId, Types.TokenMetadata> = Trie.empty();
  //owner Trie: use of Text insted of Account to improve performanances in lookup
  private stable var owners : Trie<Text, [Types.TokenId]> = Trie.empty(); //fast lookup
  //balances Trie: use of Text insted of Account to improve performanances in lookup (could also retrieve this from owners[account].size())
  private stable var balances : Trie<Text, Nat> = Trie.empty(); //fast lookup

  //approvals by account Trie
  private stable var tokenApprovals : Trie<Types.TokenId, [Types.TokenApproval]> = Trie.empty();
  //approvals by operator Trie: use of Text insted of Account to improve performanances in lookup
  private stable var operatorApprovals : Trie<Text, [Types.OperatorApproval]> = Trie.empty();

  //transactions Trie
  private stable var transactions : Trie<Types.TransactionId, Types.Transaction> = Trie.empty();
  //transactions by operator Trie: use of Text insted of Account to improve performanances in lookup
  private stable var transactionsByAccount : Trie<Text, [Types.TransactionId]> = Trie.empty();

  // we do this to have shorter type names and thus better readibility
  // see https://internetcomputer.org/docs/current/motoko/main/base/Trie
  type Trie<K, V> = Trie.Trie<K, V>;
  type Key<K> = Trie.Key<K>;

  // we have to provide `put`, `get` and `remove` with
  // a record of type `Key<K> = { hash: Hash.Hash; key: K }`;
  // thus we define the following function that takes a value of type `K`
  // (in this case `Text`) and returns a `Key<K>` record.
  // see https://internetcomputer.org/docs/current/motoko/main/base/Trie
  private func _keyFromTokenId(t : Types.TokenId) : Key<Types.TokenId> {
    { hash = Hash.hash t; key = t };
  };
  private func _keyFromText(t : Text) : Key<Text> {
    { hash = Text.hash t; key = t };
  };
  private func _keyFromTransactionId(t : Types.TransactionId) : Key<Types.TransactionId> {
    { hash = Hash.hash t; key = t };
  };

  public shared ({ caller }) func test() : async Types.BadgeReceipt {
    return #Ok {
      tokenId = 100;
      owner = { owner = caller; subaccount = null };
      metadata : [(Text, Text)] = [("Key1", "Value1")];
      reputation = {
        reviewer : Text = Principal.toText(caller);
        category : Text = "IC";
        value : Nat8 = 10;
      };
    };
  };

  public shared ({ caller }) func issueToken(args : Types.RequestType) : async Types.BadgeReceipt {
    switch (args) {
      case (#Certficate(data)) {
        // issue SBT
        let default_arg = {
          eventType : Types.EventName = #InstantReputationUpdateEvent;
          number : Text = "1001";
          image : Text = "dataurl";
          publisher : Text = "Test Publisher";
          graduate : ?Principal = ?Principal.fromText("aaaaa-aa");
          username : Text = "Ivona Drake";
          subject : Text = "Motoko Basic Course";
          date : Text = "17 Nov 2023";
          expire_at : ?Text = null;
          metadata : [(Text, Text)] = [];
          reputation = {
            reviewer = data.reputation.reviewer;
            category : Text = data.reputation.category;
            value : Nat8 = data.reputation.value;
          };
        };
        let issue_result = await issueSBT(
          {
            owner = Option.get<Principal>(data.graduate, data.reputation.reviewer);
            subaccount = null;
          },
          Utils.convertTextPairsToNetadata(data.metadata),
          {
            category = data.reputation.category;
            value = data.reputation.value;
          },
        );
        switch (issue_result) {
          case (#Err(err)) {
            return #Err(#GenericError { error_code = 100; message = " Error" });
          };
          case (#Ok(res)) {
            switch (data.eventType) {
              case (#InstantReputationUpdateEvent) {
                // call event hub
                let hub_instant_canister : Types.InstantReputationUpdateEvent = actor (hub_canister_id);

                let event : Types.Event = {
                  eventType : Types.EventName = #InstantReputationUpdateEvent;
                  topics : [Types.EventField] = [];
                  details = null;
                  reputation_change = {
                    user = caller;
                    reviewer = ?caller;
                    value = ?Nat8.toNat(data.reputation.value);
                    category = data.reputation.category;
                    source = (Principal.toText(Principal.fromActor(Self)), res);
                    timestamp : Nat = Option.get<Nat>(Nat.fromText(Int.toText(Time.now())), 0);
                    comment = ?data.subject;
                    metadata : [(Text, Types.Metadata)] = Utils.convertTextPairsToNetadata(data.metadata);
                  };
                  sender_hash = null;
                };
                let emitInstantResult = await hub_instant_canister.emitEvent(event);
                return #Ok {
                  tokenId = res;
                  owner = { owner = caller; subaccount = null };
                  metadata : [(Text, Text)] = data.metadata;
                  reputation = {
                    reviewer : Text = Principal.toText(caller);
                    category : Text = data.reputation.category;
                    value : Nat8 = data.reputation.value;
                  };
                };
              };
              case (_) {};
            };

          };
        };

      };
      case (#EventBadge(data)) {};
      case (#SimpleToken(data)) {};
      case (#TokenWithEvent(data)) {};
      case (#Other(data)) {};

    };

    #Err(#Unauthorized);
  };

  public shared ({ caller }) func issueSBT(
    to : Types.Account,
    metadata : [(Text, Types.Metadata)],
    reputation : {
      category : Text;
      value : Nat8;
    },
  ) : async Types.MintReceipt {
    let mint_args = {
      to = to;
      token_id = next_token_id;
      metadata = metadata;
    };
    let result = await mint(mint_args);
    next_token_id += 1;
    switch (result) {
      case (#Ok(reciept)) {};
      case (#Err(err)) { return #Err(#Unauthorized) };
    };
    return result;
  };

  func addMetadata(oldMetadata : [(Text, Types.Metadata)], newMetadata : [(Text, Types.Metadata)]) : [(Text, Types.Metadata)] {
    Utils.appendArrays(oldMetadata, newMetadata);
  };

  public func getSoulboundToken(user : Principal) : async Types.Result<Types.SoulboundToken, Types.CallError> {
    let res_tokenid = await icrc7_tokens_of({ owner = user; subaccount = null });
    switch (res_tokenid) {
      case (#Err(err)) { return #Err(#TokenNotFound) };
      case (#Ok(id)) {
        let res_metadata = await icrc7_metadata(id[0]); // TODO get reputation token instead of [0]
        switch (res_metadata) {
          case (#Err(_)) {
            return #Err(#TokenNotFound);
          };
          case (#Ok(metadata)) {
            let text_pairs_metadata : [(Text, Text)] = Utils.convertMetadataToTextPairs(metadata);
            #Ok {
              tokenId : Types.TokenId = id[0];
              owner : Types.Account = { owner = user; subaccount = null };
              metadata : [(Text, Text)] = text_pairs_metadata;
            };
          };
        };
      };
    };
  };

  public func updateMetadata(tokenId : Types.TokenId, newMetadata : [(Text, Types.Metadata)]) : async Types.Result<Types.TokenId, Types.MintError> {
    let tokensResult = Trie.get(tokens, _keyFromTokenId tokenId, Nat.equal);
    let token = switch (tokensResult) {
      case null return #Err(#GenericError { error_code = tokenId; message = "Token not exists" });
      case (?_elem) _elem;
    };

    let newToken : Types.TokenMetadata = {
      tokenId = tokenId;
      owner = owner;
      metadata = addMetadata(token.metadata, newMetadata);
    };
    tokens := Trie.put(tokens, _keyFromTokenId tokenId, Nat.equal, newToken).0;

    // _addTokenToOwners(acceptedTo, mintArgs.token_id);

    // _incrementBalance(acceptedTo);

    _incrementTotalSupply(1);

    let transaction : Types.Transaction = _addTransaction(#mint, Nat64.fromIntWrap(Time.now()), ?[tokenId], ?token.owner, null, null, null, null, null);

    #Ok(tokenId);
  };

  public shared query func icrc7_collection_metadata() : async Types.CollectionMetadata {
    return {
      name = name;
      symbol = symbol;
      royalties = royalties;
      royaltyRecipient = royaltyRecipient;
      description = description;
      image = image;
      totalSupply = totalSupply;
      supplyCap = supplyCap;
    };
  };

  public shared query func icrc7_name() : async Text {
    return name;
  };

  public shared query func icrc7_symbol() : async Text {
    return symbol;
  };

  public shared query func icrc7_royalties() : async ?Nat16 {
    return royalties;
  };

  public shared query func icrc7_royalty_recipient() : async ?Types.Account {
    return royaltyRecipient;
  };

  public shared query func icrc7_description() : async ?Text {
    return description;
  };

  public shared query func icrc7_image() : async ?Text {
    return image;
  };

  public shared query func icrc7_total_supply() : async Nat {
    return totalSupply;
  };

  public shared query func icrc7_supply_cap() : async ?Nat {
    return supplyCap;
  };

  public shared query func icrc7_metadata(tokenId : Types.TokenId) : async Types.MetadataResult {
    let item = Trie.get(tokens, _keyFromTokenId tokenId, Nat.equal);
    switch (item) {
      case null {
        return #Err(#InvalidTokenId);
      };
      case (?_elem) {
        return #Ok(_elem.metadata);
      };
    };
  };

  public shared query func icrc7_owner_of(tokenId : Types.TokenId) : async Types.OwnerResult {
    let item = Trie.get(tokens, _keyFromTokenId tokenId, Nat.equal);
    switch (item) {
      case null {
        return #Err(#InvalidTokenId);
      };
      case (?_elem) {
        return #Ok(_elem.owner);
      };
    };
  };

  public shared query func icrc7_balance_of(account : Types.Account) : async Types.BalanceResult {
    let acceptedAccount : Types.Account = _acceptAccount(account);
    let accountText : Text = Utils.accountToText(acceptedAccount);
    let item = Trie.get(balances, _keyFromText accountText, Text.equal);
    switch (item) {
      case null {
        return #Ok(0);
      };
      case (?_elem) {
        return #Ok(_elem);
      };
    };
  };

  public shared query func icrc7_tokens_of(account : Types.Account) : async Types.TokensOfResult {
    let acceptedAccount : Types.Account = _acceptAccount(account);
    let accountText : Text = Utils.accountToText(acceptedAccount);
    let item = Trie.get(owners, _keyFromText accountText, Text.equal);
    switch (item) {
      case null {
        return #Err(#TokenNotFound);
      };
      case (?_elem) {
        return #Ok(_elem);
      };
    };
  };

  public shared ({ caller }) func icrc7_transfer(transferArgs : Types.TransferArgs) : async Types.TransferReceipt {
    // Soulbound check
    if (transferArgs.to.owner != caller) return #Err(#Unauthorized({ token_ids = transferArgs.token_ids }));

    let now = Nat64.fromIntWrap(Time.now());

    let callerSubaccount : Types.Subaccount = switch (transferArgs.spender_subaccount) {
      case null _getDefaultSubaccount();
      case (?_elem) _elem;
    };
    let acceptedCaller : Types.Account = _acceptAccount({
      owner = caller;
      subaccount = ?callerSubaccount;
    });

    let acceptedFrom : Types.Account = switch (transferArgs.from) {
      case null acceptedCaller;
      case (?_elem) _acceptAccount(_elem);
    };

    let acceptedTo : Types.Account = _acceptAccount(transferArgs.to);

    if (transferArgs.created_at_time != null) {
      if (Nat64.less(Utils.nullishCoalescing<Nat64>(transferArgs.created_at_time, 0), now - TX_WINDOW - PERMITTED_DRIFT)) {
        return #Err(#TooOld());
      };

      if (Nat64.greater(Utils.nullishCoalescing<Nat64>(transferArgs.created_at_time, 0), now + PERMITTED_DRIFT)) {
        return #Err(#CreatedInFuture({ ledger_time = now }));
      };

    };

    if (transferArgs.token_ids.size() == 0) {
      return #Err(#GenericError({ error_code = _transferErrorCodeToCode(#EmptyTokenIds); message = _transferErrorCodeToText(#EmptyTokenIds) }));
    };

    //no duplicates in token ids are allowed
    let duplicatesCheckHashMap = HashMap.HashMap<Types.TokenId, Bool>(5, Nat.equal, Hash.hash);
    for (tokenId in transferArgs.token_ids.vals()) {
      let duplicateCheck = duplicatesCheckHashMap.get(tokenId);
      if (duplicateCheck != null) {
        return #Err(#GenericError({ error_code = _transferErrorCodeToCode(#DuplicateInTokenIds); message = _transferErrorCodeToText(#DuplicateInTokenIds) }));
      };
    };

    //by default is_atomic is true
    let isAtomic : Bool = Utils.nullishCoalescing<Bool>(transferArgs.is_atomic, true);

    //? should be added here deduplication?

    if (isAtomic) {
      let errors = Buffer.Buffer<Types.TransferError>(0); // Creates a new Buffer
      for (tokenId in transferArgs.token_ids.vals()) {
        let transferResult = _singleTransfer(?acceptedCaller, acceptedFrom, acceptedTo, tokenId, true, now);
        switch (transferResult) {
          case null {};
          case (?_elem) errors.add(_elem);
        };
      };

      //todo errors should be re-processed to aggregate tokenIds in order to have them in a single token_ids array (Unanthorized standard specifications)
      if (errors.size() > 0) {
        return #Err(errors.get(0));
      };
    };

    let transferredTokenIds = Buffer.Buffer<Types.TokenId>(0); //Creates a new Buffer of transferred tokens
    let errors = Buffer.Buffer<Types.TransferError>(0); // Creates a new Buffer
    for (tokenId in transferArgs.token_ids.vals()) {
      let transferResult = _singleTransfer(?acceptedCaller, acceptedFrom, acceptedTo, tokenId, false, now);
      switch (transferResult) {
        case null transferredTokenIds.add(tokenId);
        case (?_elem) errors.add(_elem);
      };
    };

    if (isAtomic) {
      assert (errors.size() == 0);
    };

    //? it's not clear if return the Err or Ok
    if (errors.size() > 0) {
      return #Err(errors.get(0));
    };

    let transferId : Nat = transferSequentialIndex;
    _incrementTransferIndex();

    let transaction : Types.Transaction = _addTransaction(#icrc7_transfer, now, ?Buffer.toArray(transferredTokenIds), ?acceptedTo, ?acceptedFrom, ?acceptedCaller, transferArgs.memo, transferArgs.created_at_time, null);

    return #Ok(transferId);
  };

  public shared ({ caller }) func icrc7_approve(approvalArgs : Types.ApprovalArgs) : async Types.ApprovalReceipt {
    let now = Nat64.fromIntWrap(Time.now());

    let callerSubaccount : Types.Subaccount = switch (approvalArgs.from_subaccount) {
      case null _getDefaultSubaccount();
      case (?_elem) _elem;
    };
    let acceptedFrom : Types.Account = _acceptAccount({
      owner = caller;
      subaccount = ?callerSubaccount;
    });

    let acceptedSpender : Types.Account = _acceptAccount(approvalArgs.spender);

    if (Utils.compareAccounts(acceptedFrom, acceptedSpender) == #equal) {
      return #Err(#GenericError({ error_code = _approveErrorCodeToCode(#SelfApproval); message = _approveErrorCodeToText(#SelfApproval) }));
    };

    if (approvalArgs.created_at_time != null) {
      if (Nat64.less(Utils.nullishCoalescing<Nat64>(approvalArgs.created_at_time, 0), now - TX_WINDOW - PERMITTED_DRIFT)) {
        return #Err(#TooOld());
      };
    };

    let tokenIds : [Types.TokenId] = switch (approvalArgs.token_ids) {
      case null [];
      case (?_elem) _elem;
    };

    let unauthorizedTokenIds = Buffer.Buffer<Types.ApprovalId>(0);

    for (tokenId in tokenIds.vals()) {
      if (_exists(tokenId) == false) {
        unauthorizedTokenIds.add(tokenId);
      } else if (_isOwner(acceptedFrom, tokenId) == false) {
        //check if the from is owner of approved token
        unauthorizedTokenIds.add(tokenId);
      };
    };

    if (unauthorizedTokenIds.size() > 0) {
      return #Err(#Unauthorized({ token_ids = Buffer.toArray(unauthorizedTokenIds) }));
    };

    let approvalId : Types.ApprovalId = _createApproval(acceptedFrom, acceptedSpender, tokenIds, approvalArgs.expires_at, approvalArgs.memo, approvalArgs.created_at_time);

    let transaction : Types.Transaction = _addTransaction(#icrc7_approve, now, approvalArgs.token_ids, null, ?acceptedFrom, ?acceptedSpender, approvalArgs.memo, approvalArgs.created_at_time, approvalArgs.expires_at);

    return #Ok(approvalId);
  };

  public shared query func icrc7_supported_standards() : async [Types.SupportedStandard] {
    return [{
      name = "ICRC-7";
      url = "https://github.com/dfinity/ICRC/ICRCs/ICRC-7";
    }];
  };

  public shared query func get_collection_owner() : async Types.Account {
    return owner;
  };

  public shared ({ caller }) func burn(burnArg : Types.TransferArgs) : async Types.TransferReceipt {
    let transferArgs : Types.TransferArgs = {
      created_at_time = burnArg.created_at_time;
      from = burnArg.from;
      is_atomic = null;
      memo = null;
      spender_subaccount = null;
      to = { owner = caller; subaccount = null };
      token_ids = burnArg.token_ids;
    };
    await icrc7_transfer(burnArg);
  };

  public shared ({ caller }) func mint(mintArgs : Types.MintArgs) : async Types.MintReceipt {
    let now = Nat64.fromIntWrap(Time.now());
    let acceptedTo : Types.Account = _acceptAccount(mintArgs.to);

    //todo add a more complex roles management
    // if (Principal.notEqual(caller, owner.owner)) {
    //   return #Err(#Unauthorized);
    // };

    //check on supply cap overflow
    if (supplyCap != null) {
      let _supplyCap : Nat = Utils.nullishCoalescing<Nat>(supplyCap, 0);
      if (totalSupply + 1 > _supplyCap) {
        return #Err(#SupplyCapOverflow);
      };
    };

    //cannot mint to zero principal
    if (Principal.equal(acceptedTo.owner, NULL_PRINCIPAL)) {
      return #Err(#InvalidRecipient);
    };

    //cannot mint an existing token id
    let alreadyExists = _exists(mintArgs.token_id);
    if (alreadyExists) {
      return #Err(#AlreadyExistTokenId);
    };

    //create the new token
    let newToken : Types.TokenMetadata = {
      tokenId = mintArgs.token_id;
      owner = acceptedTo;
      metadata = mintArgs.metadata;
    };

    //update the token metadata
    let tokenId : Types.TokenId = mintArgs.token_id;
    tokens := Trie.put(tokens, _keyFromTokenId tokenId, Nat.equal, newToken).0;

    _addTokenToOwners(acceptedTo, mintArgs.token_id);

    _incrementBalance(acceptedTo);

    _incrementTotalSupply(1);

    let transaction : Types.Transaction = _addTransaction(#mint, now, ?[mintArgs.token_id], ?acceptedTo, null, null, null, null, null);

    return #Ok(mintArgs.token_id);
  };

  public func get_transactions(getTransactionsArgs : Types.GetTransactionsArgs) : async Types.GetTransactionsResult {
    let result : Types.GetTransactionsResult = switch (getTransactionsArgs.account) {
      case null {
        let allTransactions : [Types.Transaction] = Trie.toArray<Types.TransactionId, Types.Transaction, Types.Transaction>(
          transactions,
          func(k, v) = v,
        );

        let checkedOffset = Nat.min(Array.size(allTransactions), getTransactionsArgs.offset);
        let length = Nat.min(getTransactionsArgs.limit, Array.size(allTransactions) - checkedOffset);
        let subArray : [Types.Transaction] = Array.subArray<Types.Transaction>(allTransactions, checkedOffset, length);
        {
          total = Array.size(allTransactions);
          transactions = subArray;
        };
      };
      case (?_elem) {
        let acceptedAccount : Types.Account = _acceptAccount(_elem);
        let accountText : Text = Utils.accountToText(acceptedAccount);
        let accountTransactions : [Types.TransactionId] = Utils.nullishCoalescing<[Types.TransactionId]>(Trie.get(transactionsByAccount, _keyFromText accountText, Text.equal), []);
        let reversedAccountTransactions : [Types.TransactionId] = Array.reverse(accountTransactions);

        let checkedOffset = Nat.min(Array.size(reversedAccountTransactions), getTransactionsArgs.offset);
        let length = Nat.min(getTransactionsArgs.limit, Array.size(reversedAccountTransactions) - checkedOffset);
        let subArray : [Types.TransactionId] = Array.subArray<Types.TransactionId>(reversedAccountTransactions, checkedOffset, length);

        let returnedTransactions = Buffer.Buffer<Types.Transaction>(0);

        for (transactionId in subArray.vals()) {
          let transaction = Trie.get(transactions, _keyFromTransactionId transactionId, Nat.equal);
          switch (transaction) {
            case null {};
            case (?_elem) returnedTransactions.add(_elem);
          };
        };

        {
          total = Array.size(reversedAccountTransactions);
          transactions = Buffer.toArray(returnedTransactions);
        };
      };
    };
    return result;
  };

  // private func _addTokenToOwners(account : Types.Account, tokenId : Types.TokenId) {
  //   //get Textual rapresentation of the Account
  //   let textAccount : Text = Utils.accountToText({
  //     owner = account.owner;
  //     subaccount = null;
  //   });

  //   //find the token owned by an account, in order to replace it
  //   let existingToken = Trie.get(owners, _keyFromText textAccount, Text.equal);

  //   switch (existingToken) {
  //     case (null) {
  //       owners := Trie.put(owners, _keyFromText textAccount, Text.equal, tokenId).0;
  //     };
  //     case (?elem) {};
  //   };

  // };

  private func _addTokenToOwners(account : Types.Account, tokenId : Types.TokenId) {
    //get Textual rapresentation of the Account
    let textAccount : Text = Utils.accountToText(account);

    //find the tokens owned by an account, in order to add the new one
    let newOwners = Utils.nullishCoalescing<[Types.TokenId]>(Trie.get(owners, _keyFromText textAccount, Text.equal), []);

    //add the token id
    owners := Trie.put(owners, _keyFromText textAccount, Text.equal, Utils.pushIntoArray<Types.TokenId>(tokenId, newOwners)).0;
  };

  private func _removeTokenFromOwners(account : Types.Account, tokenId : Types.TokenId) {
    //get Textual rapresentation of the Account
    let textAccount : Text = Utils.accountToText(account);

    //find the tokens owned by an account, in order to add the new one
    let newOwners = Utils.nullishCoalescing<[Types.TokenId]>(Trie.get(owners, _keyFromText textAccount, Text.equal), []);

    let updated : [Types.TokenId] = Array.filter<Types.TokenId>(newOwners, func x = x != tokenId);

    //add the token id
    owners := Trie.put(owners, _keyFromText textAccount, Text.equal, updated).0;
  };

  private func _incrementBalance(account : Types.Account) {
    //get Textual rapresentation of the Account
    let textAccount : Text = Utils.accountToText(account);

    //find the balance of an account, in order to increment
    let balanceResult = Trie.get(balances, _keyFromText textAccount, Text.equal);

    let actualBalance : Nat = switch (balanceResult) {
      case null 0;
      case (?_elem) _elem;
    };

    //update the balance
    balances := Trie.put(balances, _keyFromText textAccount, Text.equal, actualBalance + 1).0;
  };

  private func _decrementBalance(account : Types.Account) {
    //get Textual rapresentation of the Account
    let textAccount : Text = Utils.accountToText(account);

    //find the balance of an account, in order to increment
    let balanceResult = Trie.get(balances, _keyFromText textAccount, Text.equal);

    let actualBalance : Nat = Utils.nullishCoalescing<Nat>(balanceResult, 0);

    //update the balance
    if (actualBalance > 0) {
      balances := Trie.put(balances, _keyFromText textAccount, Text.equal, (actualBalance - 1) : Nat).0;
    };
  };

  //increment the total supply
  private func _incrementTotalSupply(quantity : Nat) {
    totalSupply := totalSupply + quantity;
  };

  private func _singleTransfer(caller : ?Types.Account, from : Types.Account, to : Types.Account, tokenId : Types.TokenId, dryRun : Bool, now : Nat64) : ?Types.TransferError {
    //check if token exists
    if (_exists(tokenId) == false) {
      return ? #Unauthorized({
        token_ids = [tokenId];
      });
    };

    //check if caller is owner or approved to transferred token
    switch (caller) {
      case null {};
      case (?_elem) {
        if (_isApprovedOrOwner(_elem, tokenId, now) == false) {
          return ? #Unauthorized({
            token_ids = [tokenId];
          });
        };
      };
    };

    //check if the from is owner of transferred token
    if (_isOwner(from, tokenId) == false) {
      return ? #Unauthorized({
        token_ids = [tokenId];
      });
    };

    if (dryRun == false) {
      _deleteAllTokenApprovals(tokenId);
      // _removeTokenFromOwners(from, tokenId);
      _decrementBalance(from);

      //change the token owner
      _updateToken(tokenId, ?to, null);

      _addTokenToOwners(to, tokenId);
      _incrementBalance(to);
    };

    return null;
  };

  func _updateToken(tokenId : Types.TokenId, newOwner : ?Types.Account, newMetadata : ?[(Text, Types.Metadata)]) {
    let item = Trie.get(tokens, _keyFromTokenId tokenId, Nat.equal);

    switch (item) {
      case null {
        return;
      };
      case (?_elem) {
        //update owner
        let newToken : Types.TokenMetadata = {
          tokenId = _elem.tokenId;
          owner = Utils.nullishCoalescing<Types.Account>(newOwner, _elem.owner);
          metadata = Utils.nullishCoalescing<[(Text, Types.Metadata)]>(newMetadata, _elem.metadata);
        };

        //update the token metadata
        tokens := Trie.put(tokens, _keyFromTokenId tokenId, Nat.equal, newToken).0;
        return;
      };
    };
  };

  private func _isApprovedOrOwner(spender : Types.Account, tokenId : Types.TokenId, now : Nat64) : Bool {
    return _isOwner(spender, tokenId) or _isApproved(spender, tokenId, now);
  };

  private func _isOwner(spender : Types.Account, tokenId : Types.TokenId) : Bool {
    let item = Trie.get(tokens, _keyFromTokenId tokenId, Nat.equal);
    switch (item) {
      case null {
        return false;
      };
      case (?_elem) {
        return Utils.compareAccounts(spender, _elem.owner) == #equal;
      };
    };
  };

  private func _isApproved(spender : Types.Account, tokenId : Types.TokenId, now : Nat64) : Bool {
    let item = Trie.get(tokens, _keyFromTokenId tokenId, Nat.equal);

    switch (item) {
      case null {
        return false;
      };
      case (?_elem) {
        let ownerToText : Text = Utils.accountToText(_elem.owner);
        let approvalsByThisOperator : [Types.OperatorApproval] = Utils.nullishCoalescing<[Types.OperatorApproval]>(Trie.get(operatorApprovals, _keyFromText ownerToText, Text.equal), []);

        let approvalForThisSpender = Array.find<Types.OperatorApproval>(approvalsByThisOperator, func x = Utils.compareAccounts(spender, x.spender) == #equal and (x.expires_at == null or Nat64.greater(Utils.nullishCoalescing<Nat64>(x.expires_at, 0), now)));

        switch (approvalForThisSpender) {
          case (?_foundOperatorApproval) return true;
          case null {
            let approvalsForThisToken : [Types.TokenApproval] = Utils.nullishCoalescing<[Types.TokenApproval]>(Trie.get(tokenApprovals, _keyFromTokenId tokenId, Nat.equal), []);
            let approvalForThisToken = Array.find<Types.TokenApproval>(approvalsForThisToken, func x = Utils.compareAccounts(spender, x.spender) == #equal and (x.expires_at == null or Nat64.greater(Utils.nullishCoalescing<Nat64>(x.expires_at, 0), now)));
            switch (approvalForThisToken) {
              case (?_foundTokenApproval) return true;
              case null return false;
            };

          };
        };

        return false;
      };
    };
  };

  private func _exists(tokenId : Types.TokenId) : Bool {
    let tokensResult = Trie.get(tokens, _keyFromTokenId tokenId, Nat.equal);
    switch (tokensResult) {
      case null return false;
      case (?_elem) return true;
    };
  };

  private func _incrementTransferIndex() {
    transferSequentialIndex := transferSequentialIndex + 1;
  };

  private func _getDefaultSubaccount() : Blob {
    return Blob.fromArray([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  };

  private func _acceptAccount(account : Types.Account) : Types.Account {
    let effectiveSubaccount : Blob = switch (account.subaccount) {
      case null _getDefaultSubaccount();
      case (?_elem) _elem;
    };

    return {
      owner = account.owner;
      subaccount = ?effectiveSubaccount;
    };
  };

  private func _transferErrorCodeToCode(d : Types.TransferErrorCode) : Nat {
    switch d {
      case (#EmptyTokenIds) 0;
      case (#DuplicateInTokenIds) 1;
    };
  };

  private func _transferErrorCodeToText(d : Types.TransferErrorCode) : Text {
    switch d {
      case (#EmptyTokenIds) "Empty Token Ids";
      case (#DuplicateInTokenIds) "Duplicates in Token Ids array";
    };
  };

  private func _approveErrorCodeToCode(d : Types.ApproveErrorCode) : Nat {
    switch d {
      case (#SelfApproval) 0;
    };
  };

  private func _approveErrorCodeToText(d : Types.ApproveErrorCode) : Text {
    switch d {
      case (#SelfApproval) "No Self Approvals";
    };
  };

  //if token_ids is empty, approve entire collection
  private func _createApproval(from : Types.Account, spender : Types.Account, tokenIds : [Types.TokenId], expiresAt : ?Nat64, memo : ?Blob, createdAtTime : ?Nat64) : Types.ApprovalId {

    if (tokenIds.size() == 0) {
      //get Textual rapresentation of the Account
      let fromTextAccount : Text = Utils.accountToText(from);
      let approvalsByThisOperator : [Types.OperatorApproval] = Utils.nullishCoalescing<[Types.OperatorApproval]>(Trie.get(operatorApprovals, _keyFromText fromTextAccount, Text.equal), []);
      let newApproval : Types.OperatorApproval = {
        spender = spender;
        memo = memo;
        expires_at = expiresAt;
      };

      //add the updated approval
      operatorApprovals := Trie.put(operatorApprovals, _keyFromText fromTextAccount, Text.equal, Utils.pushIntoArray<Types.OperatorApproval>(newApproval, approvalsByThisOperator)).0;
    } else {

      for (tokenId in tokenIds.vals()) {
        let approvalsForThisToken : [Types.TokenApproval] = Utils.nullishCoalescing<[Types.TokenApproval]>(Trie.get(tokenApprovals, _keyFromTokenId tokenId, Nat.equal), []);
        let newApproval : Types.TokenApproval = {
          spender = spender;
          memo = memo;
          expires_at = expiresAt;
        };
        //add the updated approval
        tokenApprovals := Trie.put(tokenApprovals, _keyFromTokenId tokenId, Nat.equal, Utils.pushIntoArray<Types.TokenApproval>(newApproval, approvalsForThisToken)).0;
      };

    };

    let approvalId : Types.ApprovalId = approvalSequentialIndex;
    _incrementApprovalIndex();

    return approvalId;
  };

  private func _incrementApprovalIndex() {
    approvalSequentialIndex := approvalSequentialIndex + 1;
  };

  private func _deleteAllTokenApprovals(tokenId : Types.TokenId) {
    tokenApprovals := Trie.remove(tokenApprovals, _keyFromTokenId tokenId, Nat.equal).0;
  };

  private func _addTransaction(kind : { #mint; #icrc7_transfer; #icrc7_approve }, timestamp : Nat64, tokenIds : ?[Types.TokenId], to : ?Types.Account, from : ?Types.Account, spender : ?Types.Account, memo : ?Blob, createdAtTime : ?Nat64, expiresAt : ?Nat64) : Types.Transaction {
    let transactionId : Types.TransactionId = transactionSequentialIndex;
    _incrementTransactionIndex();

    let acceptedTo = Utils.nullishCoalescing<Types.Account>(to, _acceptAccount({ owner = NULL_PRINCIPAL; subaccount = ?_getDefaultSubaccount() }));
    let acceptedFrom = Utils.nullishCoalescing<Types.Account>(from, _acceptAccount({ owner = NULL_PRINCIPAL; subaccount = ?_getDefaultSubaccount() }));
    let acceptedSpender = Utils.nullishCoalescing<Types.Account>(spender, _acceptAccount({ owner = NULL_PRINCIPAL; subaccount = ?_getDefaultSubaccount() }));

    let transaction : Types.Transaction = switch kind {
      case (#mint) {
        {
          kind = "mint";
          timestamp = timestamp;
          mint = ?{
            to = acceptedTo;
            token_ids = Utils.nullishCoalescing<[Types.TokenId]>(tokenIds, []);
          };
          icrc7_transfer = null;
          icrc7_approve = null;
        };
      };
      case (#icrc7_transfer) {
        {
          kind = "icrc7_transfer";
          timestamp = timestamp;
          mint = null;
          icrc7_transfer = ?{
            from = acceptedFrom;
            to = acceptedTo;
            spender = ?acceptedSpender;
            token_ids = Utils.nullishCoalescing<[Types.TokenId]>(tokenIds, []);
            memo = memo;
            created_at_time = createdAtTime;
          };
          icrc7_approve = null;
        };
      };
      case (#icrc7_approve) {
        {
          kind = "icrc7_approve";
          timestamp = timestamp;
          mint = null;
          icrc7_transfer = null;
          icrc7_approve = ?{
            from = acceptedFrom;
            spender = acceptedSpender;
            token_ids = tokenIds;
            expires_at = expiresAt;
            memo = memo;
            created_at_time = createdAtTime;
          };
        };
      };
    };

    transactions := Trie.put(transactions, _keyFromTransactionId transactionId, Nat.equal, transaction).0;

    switch kind {
      case (#mint) {
        _addTransactionIdToAccount(transactionId, acceptedTo);
      };
      case (#icrc7_transfer) {
        _addTransactionIdToAccount(transactionId, acceptedTo);
        if (from != null) {
          if (Utils.compareAccounts(acceptedFrom, acceptedTo) != #equal) {
            _addTransactionIdToAccount(transactionId, acceptedFrom);
          };
        };
        if (spender != null) {
          if (Utils.compareAccounts(acceptedSpender, acceptedTo) != #equal and Utils.compareAccounts(acceptedSpender, acceptedFrom) != #equal) {
            _addTransactionIdToAccount(transactionId, acceptedSpender);
          };
        };
      };
      case (#icrc7_approve) {
        _addTransactionIdToAccount(transactionId, acceptedFrom);
      };
    };

    return transaction;
  };

  private func _addTransactionIdToAccount(transactionId : Types.TransactionId, account : Types.Account) {
    let accountText : Text = Utils.accountToText(_acceptAccount(account));
    let accountTransactions : [Types.TransactionId] = Utils.nullishCoalescing<[Types.TransactionId]>(Trie.get(transactionsByAccount, _keyFromText accountText, Text.equal), []);
    transactionsByAccount := Trie.put(transactionsByAccount, _keyFromText accountText, Text.equal, Utils.pushIntoArray<Types.TransactionId>(transactionId, accountTransactions)).0;
  };

  private func _incrementTransactionIndex() {
    transactionSequentialIndex := transactionSequentialIndex + 1;
  };

};
