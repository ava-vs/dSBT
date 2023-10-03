import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Principal "mo:base/Principal";
import Types "./Types"; 
import List "mo:base/List";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";

shared actor class Dip721NFT(custodian: Principal) {
  stable var transactionId: Types.TransactionId = 0;
  stable var allNfts = List.nil<Types.Nft>();
  let GLOBAL_TOKEN_SYMBOL = "DNFT";

  type NftIdList = Buffer.Buffer<Types.TokenId>;

  type TokenId = Types.TokenId;

  type Nft = Types.Nft;

  public func createMetadataFromLink(link: Text) : async [Types.MetadataPart] {
    let metadataPart: Types.MetadataPart = {
      purpose = #Preview;
      key_val_data = [{
        key = "URL";
        val = #LinkContent(link)
      }];
      data = Text.encodeUtf8(link); 
    };
    return [metadataPart];
  };

  public func mintNFTWithLink(to: Principal, link: Text) : async Types.MintReceipt {
    let metadata = await createMetadataFromLink(link);
    let newId = Nat64.fromNat(List.size(allNfts));
    let nft: Types.Nft = {
      owner = to;
      id = newId;
      metadata = metadata;
      tokenType = GLOBAL_TOKEN_SYMBOL;
    };
    allNfts := List.push(nft, allNfts);
    transactionId += 1;
    return #Ok({
      token_id = newId;
      id = transactionId;
      owner = to;
      image = "image_rep.svg";
      link  = link;
    });
  };

    public shared({ caller }) func mintNFTWithLinkWithoutTo(link: Text) : async Types.MintReceipt {

    let metadata = await createMetadataFromLink(link);
    let newId = Nat64.fromNat(List.size(allNfts));
    let nft: Types.Nft = {
      owner = caller;
      id = newId;
      metadata = metadata;
      tokenType = GLOBAL_TOKEN_SYMBOL;
    };
    allNfts := List.push(nft, allNfts);
    transactionId += 1;
    return #Ok({
      token_id = newId;
      id = transactionId;
      owner = caller;
      image = "image_rep.svg";
      link  = link;
    });
  };

  func nat64ToTokenId(n: Nat64) : TokenId {
    return n;
  };

 public func getDNftByUser(user : Principal) : async Types.NftResult {
    let userNftOpt = findLast(allNfts, user);
    
    switch (userNftOpt) {
        case (null) #Err(#NoNFT);
        case (?userNft) #Ok(userNft);
    }
  };

  private func findLast(nfts: List.List<Nft>, user: Principal) : ?Nft {
      switch (nfts) {
          case (null) null;
       case (?(head, tail)) {
            if (head.owner == user) {
                ?head
            } else {
                findLast(tail, user)
            }
        };
    }
  };  

  public query func getAllNft() : async [Nft] {
    List.toArray(allNfts);
  };

  public query func getNftHistoryByUser(user : Principal) : async [Nft] {
    let userNfts = List.filter(allNfts, func(nft: Nft) : Bool {
        nft.owner == user
    });
    List.toArray(userNfts);
  };

  public query (message) func greet() : async Text {
    return "Hello, your principal name is " # Principal.toText(message.caller);
  }
}
