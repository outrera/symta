type queue{Size} xs a b
| $xs <= dup Size 0

queue.end = $a >< $b

queue.push Item =
| $xs.($b++) <= Item
| when $b >< $xs.size: $b <= 0

queue.pop = as $xs.($a++): when $a >< $xs.size: $a <= 0

queue.reset = $a <= $b

queue.clear = // ensures we have no reference to any object
| $xs.clear{0}
| $a <= $b

export queue