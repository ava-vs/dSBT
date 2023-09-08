import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

import ICRC7 "./ICRC7";

module {
  type TokenId = ICRC7.TokenId;
  type Metadata = ICRC7.Metadata;

  public type Result<S, E> = {
    #Ok : S;
    #Err : E;
  };

  public type ApiError = {
    #Unauthorized;
    #InvalidTokenId;
    #ZeroAddress;
    #NoDNFT;
    #Other;
  };

  public type DNftResult = Result<DNft, ApiError>;

  public type MetadataResult = Result<Metadata, ApiError>;

  public type CollectionResult = Result<ICRC7.Collection, ApiError>;

  public type MetadataLog = {
    timestamp: Time.Time;
    metadata: Metadata; 
  };

  public type MetadataHistory = [MetadataLog];

  public type MintReceipt = Result<MintReceiptPart, ApiError>;

  public type MintReceiptPart = {
    token_id: TokenId;
    id: Nat;
    owner: Principal;
    image: Text;
    link: Text;
  };

  public type TxReceipt = Result<Nat, ApiError>;
  
  public type TransactionId = Nat;

  public type DNft = ICRC7.Token;
}
