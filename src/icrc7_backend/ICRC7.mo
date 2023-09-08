import Array "mo:base/Array";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";

module ICRC7 = {

  public type AccountId = Principal;

  public type TokenId = Nat;

  public type CollectionId = Nat;

  public type Metadata = [MetadataPart];

  public type MetadataPart = {
    #TextContent: Text;
    #LinkContent: Text;
    };

  public type Token = {
    id : TokenId;
    metadata : Metadata;
    owner : AccountId;
  };

  public type Subaccount = Blob;

  public type Account = { 
    owner: Principal; 
    subaccount: ?Subaccount 
    };
  
  public type Collection = {
    owner: Principal;
    metadata: CollectionMetadata;
    id: Nat;
  };

   public type CollectionMetadata = {
    icrc7_name: Text;
    icrc7_symbol: Text;
    icrc7_royalties: ?Nat16;
    icrc7_royalty_recipient: ?Account;
    icrc7_description: ?Text;
    icrc7_image: ?Blob;
    icrc7_total_supply: Nat;
    icrc7_supply_cap: ?Nat;
  };

  public type Icrc7_collection_metadata = {
    icrc7_name: Text;
    icrc7_symbol: Text;
    icrc7_royalties: ?Nat16;
    icrc7_royalty_recipient: ?Account;
    icrc7_description: ?Text;
    icrc7_image: ?Blob;
    icrc7_total_supply: Nat;
    icrc7_supply_cap: ?Nat;
  };

  public type TransferArgs = {
    from: ?Account;
    to: Account;
    token_ids: [Nat];
    memo: ?Blob;
    created_at_time: ?Nat64;
    is_atomic: ?Bool;
  };

  public type TransferError = {
    #Unauthorized : { token_ids: [Nat] };
    #TooOld;
    #TemporarilyUnavailable;
    #GenericError : { error_code: Nat; message: Text };
  };

    public type ApprovalArgs = {
      from_subaccount: ?Blob;
      to: Principal;
      tokenIds: ?[Nat];
      expires_at: ?Nat64;
      memo: ?Blob;
      created_at: ?Nat64;
  };

  public type ApprovalError = {
    #Unauthorized : [Nat];
    #TooOld;
    #TemporarilyUnavailable;
    #GenericError : { error_code: Nat; message: Text };
  };
};


