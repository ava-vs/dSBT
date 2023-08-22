import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Bool "mo:base/Bool";
import Principal "mo:base/Principal";
import Types "./Types"; 
import List "mo:base/List";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";
import Map "mo:base/HashMap";
import Buffer "mo:base/Buffer";

shared actor class Dip721NFT(custodian: Principal) {
  stable var transactionId: Types.TransactionId = 0;
  stable var allNfts = List.nil<Types.Nft>();
  let GLOBAL_TOKEN_SYMBOL = "DNFT";

  type NftIdList = Buffer.Buffer<Types.TokenId>;

  type TokenId = Types.TokenId;

  type Nft = Types.Nft;

  var dNftMap : Map.HashMap<Principal, Nft> = 
       Map.HashMap<Principal, Nft>(10, Principal.equal, Principal.hash);

  public shared({ caller }) func getDNft() : async Types.NftResult {
    
    let item = dNftMap.get(caller);
    switch (item) {
      case (null) {
        return #Err(#NoNFT);
      };
      case (?nft) {
        return #Ok(nft);
      };
    };
  };

  public func createMetadataFromLink(link: Text) : async [Types.MetadataPart] {
    let metadataPart: Types.MetadataPart = {
      purpose = #Preview;
      key_val_data = [{
        key = "URL";
        val = #LinkContent(link)
      }];
      // Преобразование текстовой ссылки в Blob
      data = Text.encodeUtf8(link); 
    };
    return [metadataPart];
  };

  public shared({ caller }) func mintNFTWithLink(to: Principal, link: Text) : async Types.MintReceipt {
    let metadata = await createMetadataFromLink(link);
    let newId = Nat64.fromNat(List.size(allNfts));
    let nft: Types.Nft = {
      owner = to;
      id = newId;
      metadata = metadata;
      tokenType = GLOBAL_TOKEN_SYMBOL;
    };
    allNfts := List.push(nft, allNfts);
    dNftMap.put(caller, nft);
    return #Ok({
      token_id = newId;
      id = transactionId;
    });
  };

    public shared({ caller }) func mintNFTWithLinkWithoutTo(link: Text) : async Types.MintReceipt {
    let check = await getDNft();
    // switch (check) { 
    //   case (#Ok(some)) return #Err(#Other);
    // };

    let metadata = await createMetadataFromLink(link);
    let newId = Nat64.fromNat(List.size(allNfts));
    let nft: Types.Nft = {
      owner = caller;
      id = newId;
      metadata = metadata;
      tokenType = GLOBAL_TOKEN_SYMBOL;
    };
    allNfts := List.push(nft, allNfts);
    dNftMap.put(caller, nft);
    return #Ok({
      token_id = newId;
      id = transactionId;
    });
  };

  func nat64ToTokenId(n: Nat64) : TokenId {
    return n;
  };

  public shared({ caller }) func getDNftByUser(user : Principal) : async Types.NftResult {
    
    let item = dNftMap.get(user);
    switch (item) {
      case (null) {
        return #Err(#NoNFT);
      };
      case (?nft) {
        return #Ok(nft);
      };
    };
  };

  public query (message) func greet() : async Text {
    return "Hello, " # Principal.toText(message.caller) # "!";
  };

  public query func getAllNft() : async [Nft] {
    List.toArray(allNfts);
  };

  public query func getNftHistoryByUser(user : Principal) : async [Nft] {
    let userNfts = List.filter(allNfts, func(nft: Nft) : Bool {
        nft.owner == user
    });
    List.toArray(userNfts);
  }

}
