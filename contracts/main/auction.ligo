
type storage_t         is [@layout:comb] record [
   min_bid             : nat;
   time_threshold      : nat;
   delay               : nat;
   highest_bit         : nat;
   admin               : address; 
   winner              : address
 ]
type parameter_t is 
| Update_admin         of address
| Config 
| Bet                  of nat

type bid_t             is nat
type return_t          is (list (operation) * storage_t)

function bet (
const bid              : bid_t; 
var store              : storage_t) 
                       : storage_t is
block {
if   bid >= store.min_bid
then patch store with record [
     store.highest_bit := bid;
     store.winner      := Tezos.sender;
     ]
else (failwith("Low bid"))
} with store

function update_admin (
const new_admin        : address;
var store              : storage_t) 
                       : storage_t is
block {
  if   Tezos.sender =/= store.admin
  then failwith ("Only admin can do it")
  else store.admin := new_admin
} with store
 
type param_t is [@layout:comb] record [
   min_bid             : nat;
   time_threshold      : nat; 
   delay               : nat;
]
function config (
  const data           : param_t;
  var store            : storage_t)
                       : storage_t is
block {
  if Tezos.sender <> store.admin
  then failwith("Only admin can do it")
  else patch store with record [
       store.min_bid        := data.min_bid;
       store.time_threshold := data.time_threshold;
       store.delay          := data.delay;
  ] with store
} 

function main (
const action           : parameter_t; 
var store              : storage_t) 
                       : return_t is 
((nil : list (operation)),
case action of
| Update_admin(new_admin)  -> update_admin (new_admin, store)
| Config(data)             -> config (data, store)
| Bet(bid)                 -> bet (bid, store)
end)