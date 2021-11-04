
type storage_t is record [
   min_bid : nat;
   time_threshold : nat;
   delay : nat;
   highest_bit : nat;
   admin : address; 
   winner : address
 ]
type parameter is Update_admin | Config | Bet
type participant is record [address: address; bet: int]
type return is list (operation) * storage_t

function bet (const My_bet : participant; const store : storage_t) : storage_t is
block {
if   My_bet.bet > min_bid
then highest_bit := bet
     winner := bet.address
else ((nil: list (operation), store))
}

function update_admin (const new_admin : address) : storage_t is
block {
  if   Tezos.source =/= storage_t.admin
  then (failwith ("Only admin can do it") : return)
  else admin := new_admin
}

function config (participant)

function main (const action : parameter; const store : storage_t) : return is 
(((nil : list (operation)), store)
case action of
  Update_admin  -> update_admin (new_admin)
| Config        -> config ()
| Bet           -> bet (My_bet, store)
end)

