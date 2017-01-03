use ecs

component xyz.3/0
component direction.3/0
component wheel{xyz direction}
component wheels.4{@wheel}
component chassis
component engine/'gasoline'

// serial gets incremented for each entitiy
component serial [custom] count
serial.new Id =
| ecs_array_set $array Id $count
| $count++

ECS = ecs 1024

Car = ECS.new{xyz,[4 5 6] serial direction chassis engine wheels}

Car.wheels.1.xyz <= [1 2 3]

say Car.wheels.1.xyz
say Car.engine
say Car.xyz

say "Wheel entities: [ECS.systems.wheel.entities]"

// dump whole ECS as text
say ECS.text
