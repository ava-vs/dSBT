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

shared actor class Dip721NFT(custodian: Principal) {
  stable var transactionId: Types.TransactionId = 0;
  stable var allNfts = List.nil<Types.Nft>();
  let GLOBAL_TOKEN_SYMBOL = "DNFT";

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
    return #Ok({
      token_id = newId;
      id = transactionId;
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
    return #Ok({
      token_id = newId;
      id = transactionId;
    });
  };

} 

