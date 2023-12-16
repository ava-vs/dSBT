import Blob "mo:base/Blob";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

module {

  public type Subaccount = Blob;

  public type Account = {
    owner : Principal;
    subaccount : ?Blob;
  };

  public type CollectionInitArgs = {
    name : Text;
    symbol : Text;
    royalties : ?Nat16;
    royaltyRecipient : ?Account;
    description : ?Text;
    image : ?Text; //todo https://github.com/dfinity/ICRC/commit/ce839e586a993c051a595bfd8386f5c041d7bf18
    supplyCap : ?Nat;
  };

  public type CollectionMetadata = {
    name : Text;
    symbol : Text;
    royalties : ?Nat16;
    royaltyRecipient : ?Account;
    description : ?Text;
    image : ?Text;
    totalSupply : Nat;
    supplyCap : ?Nat;
  };

  public type SupportedStandard = {
    name : Text;
    url : Text;
  };

  public type TokenId = Nat;

  public type Metadata = {
    #Nat : Nat;
    #Int : Int;
    #Text : Text;
    #Blob : Blob;
    #Bool : Bool;
  };

  public type TokenMetadata = {
    tokenId : TokenId;
    owner : Account;
    metadata : [(Text, Metadata)];
  };

  public type Result<S, E> = {
    #Ok : S;
    #Err : E;
  };

  public type CallError = {
    #Unauthorized;
    #InvalidTokenId;
    #AlreadyExistTokenId;
    #SupplyCapOverflow;
    #InvalidRecipient;
    #GenericError;
    #TokenNotFound;
  };

  public type MintArgs = {
    to : Account;
    token_id : TokenId;
    metadata : [(Text, Metadata)];
  };

  public type ReputationChangeRequest = {
    user : Principal;
    reviewer : ?Principal;
    value : ?Nat;
    category : Text;
    timestamp : Nat;
    source : (Text, Nat); // (doctoken_canisterId, documentId)
    comment : ?Text;
    metadata : [(Text, Metadata)];
  };

  public type Event = {
    eventType : EventName;
    topics : [EventField];
    details : ?Text;
    reputation_change : ReputationChangeRequest;
    sender_hash : ?Text;
  };

  public type IssueArgs = {
    mint_args : MintArgs;
    reputation : Reputation;
  };

  public type RepArgs = IssueArgs;

  public type TransferId = Nat;

  public type TransferArgs = {
    spender_subaccount : ?Subaccount; // the subaccount of the caller (used to identify the spender)
    from : ?Account; /* if supplied and is not caller then is permit transfer, if not supplied defaults to subaccount 0 of the caller principal */
    to : Account;
    token_ids : [TokenId];
    // type: leave open for now
    memo : ?Blob;
    created_at_time : ?Nat64;
    is_atomic : ?Bool;
  };

  public type TransferError = {
    #Unauthorized : { token_ids : [TokenId] };
    #TooOld;
    #CreatedInFuture : { ledger_time : Nat64 };
    #Duplicate : { duplicate_of : TransferId };
    #TemporarilyUnavailable : {};
    #GenericError : { error_code : Nat; message : Text };
  };

  public type ApprovalId = Nat;

  public type ApprovalArgs = {
    from_subaccount : ?Subaccount;
    spender : Account; // Approval is given to an ICRC Account
    token_ids : ?[TokenId]; // if no tokenIds given then approve entire collection
    expires_at : ?Nat64;
    memo : ?Blob;
    created_at_time : ?Nat64;
  };

  public type ApprovalError = {
    #Unauthorized : { token_ids : [TokenId] };
    #TooOld;
    #TemporarilyUnavailable : {};
    #GenericError : { error_code : Nat; message : Text };
  };

  public type MintError = {
    #Unauthorized;
    #SupplyCapOverflow;
    #InvalidRecipient;
    #AlreadyExistTokenId;
    #GenericError : { error_code : Nat; message : Text };
  };

  public type MetadataResult = Result<[(Text, Metadata)], CallError>;

  public type OwnerResult = Result<Account, CallError>;

  public type BalanceResult = Result<Nat, CallError>;

  public type TokensOfResult = Result<[TokenId], CallError>;

  public type MintReceipt = Result<TokenId, MintError>;

  public type BadgeReceipt = Result<Badge, MintError>;

  public type Badge = {
    tokenId : TokenId;
    owner : Account;
    metadata : [(Text, Text)];
    reputation : {
      reviewer : Text;
      category : Text;
      value : Nat8;
    };
  };

  public type TransferReceipt = Result<TransferId, TransferError>;

  public type ApprovalReceipt = Result<ApprovalId, ApprovalError>;

  public type TransferErrorCode = {
    #EmptyTokenIds;
    #DuplicateInTokenIds;
  };

  public type ApproveErrorCode = {
    #SelfApproval;
  };

  public type OperatorApproval = {
    spender : Account;
    memo : ?Blob;
    expires_at : ?Nat64;
  };

  public type TokenApproval = {
    spender : Account;
    memo : ?Blob;
    expires_at : ?Nat64;
  };

  public type TransactionId = Nat;

  //base on https://github.com/dfinity/ICRC-1/tree/roman-icrc3/standards/ICRC-3
  public type Transaction = {
    kind : Text; // "icrc7_transfer" | "mint" ...
    timestamp : Nat64;
    mint : ?{
      to : Account;
      token_ids : [TokenId];
    };
    icrc7_transfer : ?{
      from : Account;
      to : Account;
      spender : ?Account;
      token_ids : [TokenId];
      memo : ?Blob;
      created_at_time : ?Nat64;
    };
    icrc7_approve : ?{
      from : Account;
      spender : Account;
      token_ids : ?[TokenId];
      expires_at : ?Nat64;
      memo : ?Blob;
      created_at_time : ?Nat64;
    };
  };

  public type GetTransactionsArgs = {
    limit : Nat;
    offset : Nat;
    account : ?Account;
  };

  public type GetTransactionsResult = {
    total : Nat;
    transactions : [Transaction];
  };

  public type CreateEvent = actor {
    emitEvent : Event -> async Result.Result<[(Text, Text)], Text>;
  };

  // public type Event = {
  //   eventType : EventName;
  //   topics : [EventField];
  //   tokenId : ?Nat;
  //   owner : ?Principal;
  //   metadata : ?[(Text, Text)];
  //   creationDate : ?Int;
  // };

  public type Reputation = {
    user : Principal;
    reviewer : Principal;
    value : Nat8;
    comment : Text;
    category : Text;
  };

  public type Subscriber = {
    callback : Principal;
    filter : EventFilter;
  };

  public type EventFilter = {
    eventType : ?EventName;
    fieldFilters : [EventField];
  };

  public type EventField = {
    name : Text;
    value : Blob;
  };

  public type InstantReputationUpdateEvent = actor {
    getCategories : () -> async [(Text, Text)];
    emitEvent : (Event) -> async [Subscriber];
  };

  public type EventName = {
    #CreateEvent;
    #BurnEvent;
    #CollectionCreatedEvent;
    #CollectionUpdatedEvent;
    #CollectionDeletedEvent;
    #AddToCollectionEvent;
    #RemoveFromCollectionEvent;
    #InstantReputationUpdateEvent;
    #AwaitingReputationUpdateEvent;
    #NewRegistrationEvent;
    #FeedbackSubmissionEvent;
    #Unknown;
  };
  public type SoulboundToken = {
    tokenId : TokenId;
    owner : Account;
    metadata : [(Text, Text)];
  };

  public type RequestType = {
    #Certficate : {
      eventType : EventName;
      number : Text;
      image : Text;
      publisher : Text;
      graduate : ?Principal;
      username : Text;
      subject : Text;
      date : Text;
      expire_at : ?Text;
      metadata : [(Text, Text)];
      reputation : {
        reviewer : Principal;
        category : Text;
        value : Nat8;
      };
    };
    #EventBadge : {
      soulbound : SoulboundToken;
      eventType : EventName;
      number : Text;
      image : Text;
      publisher : Text;
      username : Text;
      subject : Text;
      role : Text;
      result : Text;
      date : Text;
      reputation : {
        reviewer : Text;
        category : Text;
        value : Nat8;
      };
    };
    #SimpleToken : {
      data : SoulboundToken;
    };
    #TokenWithEvent : {
      soulbound : SoulboundToken;
      eventType : EventName;
      reputation : {
        reviewer : Text;
        category : Text;
        value : Nat8;
      };
    };
    #Other : {
      soulbound : SoulboundToken;
      reputation : {
        reviewer : Text;
        category : Text;
        value : Nat8;
      };
    };
  };
};
