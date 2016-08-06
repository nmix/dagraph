# Directed Acyclic Graph

#### Dagraph provides DAG functionality to ActiveRecord models
![Example](https://upload.wikimedia.org/wikipedia/commons/0/08/Directed_acyclic_graph.png)

[DAG description](https://en.wikipedia.org/wiki/Directed_acyclic_graph)
[RU](https://ru.wikipedia.org/wiki/Направленный_ациклический_граф)

## Installation
1) Gemfile
```ruby
gem 'dagraph', github: 'nmix/dagraph'
```
2) Install gem
```bash
bundle install
```
3) Generate migration and run migrate
```bash
bin/rails generate dagraph:migration
bin/rake db:migrate
```
4) Add `acs_as_dagraph` to model
```ruby
class Unit < ActiveRecord::Base
	acts_as_dagraph
end
```

## Usage
![Example](https://upload.wikimedia.org/wikipedia/commons/0/08/Directed_acyclic_graph.png)

### Creation
```ruby
# create units
unit7 = Unit.create(code: "7")
unit5 = Unit.create(code: "5")
unit3 = ...
# create graph with weights
unit7.add_child(unit11, 4)
unit7.add_child(unit8, 1)
unit5.add_child(unit11, 6)
unit3.add_child(unit8, 5)
unit3.add_child(unit10, 7)

unit2.add_parent(unit11, 9)
unit9.add_parent(unit11, 2)
unit9.add_parent(unit8, 1)
unit10.add_parent(unit11, 1)
```

### Children and parents

Get all children (direct descendants)
```ruby
unit7.children
# => [#<Unit id: 4, code: "11">, #<Unit id: 5, code: "8">]
```
Get all parents (direct ancestors)
```ruby
unit8.parents
# => [#<Unit id: 1, code: "7">, #<Unit id: 3, code: "3">]
```

### Routing

Get all of the routes passing through the node (`{route_id => [nodes], ...`)
```ruby
unit11.routing
# => {1=>[#<Unit id: 1, code: "7">, #<Unit id: 4, code: "11">, #<Unit id: 7, code: "9">], 3=>[#<Unit id: 1, code: "7">, #<Unit id: 4, code: "11">, #<Unit id: 8, code: "10">], 4=>[#<Unit id: 2, code: "5">, #<Unit id: 4, code: "11">, #<Unit id: 7, code: "9">], 5=>[#<Unit id: 2, code: "5">, #<Unit id: 4, code: "11">, #<Unit id: 8, code: "10">], 6=>[#<Unit id: 1, code: "7">, #<Unit id: 4, code: "11">, #<Unit id: 6, code: "2">], 7=>[#<Unit id: 2, code: "5">, #<Unit id: 4, code: "11">, #<Unit id: 6, code: "2">]}

unit10.routing
# => {3=>[#<Unit id: 1, code: "7">, #<Unit id: 4, code: "11">, #<Unit id: 8, code: "10">], 5=>[#<Unit id: 2, code: "5">, #<Unit id: 4, code: "11">, #<Unit id: 8, code: "10">], 9=>[#<Unit id: 3, code: "3">, #<Unit id: 8, code: "10">]}
```

### Descendants and ancestors
Get all descendants (split to routes)
```ruby
unit5.descendats
# => [[#<Unit id: 4, code: "11">, #<Unit id: 7, code: "9">], [#<Unit id: 4, code: "11">, #<Unit id: 8, code: "10">], [#<Unit id: 4, code: "11">, #<Unit id: 6, code: "2">]]
```
Get all uniq descendants (without routes)
```ruby
unit5.descendats.flatten.uniq
# => [#<Unit id: 4, code: "11">, #<Unit id: 7, code: "9">, #<Unit id: 8, code: "10">, #<Unit id: 6, code: "2">]
```
Get all ancestors (split to routes)
```ruby
unit10.ancestors
# => [[#<Unit id: 1, code: "7">, #<Unit id: 4, code: "11">], [#<Unit id: 2, code: "5">, #<Unit id: 4, code: "11">], [#<Unit id: 3, code: "3">]]
```
Get all uniq ancestors (without routes)
```ruby
unit10.ancestors.flatten.uniq
# => [#<Unit id: 1, code: "7">, #<Unit id: 4, code: "11">, #<Unit id: 2, code: "5">, #<Unit id: 3, code: "3">]
```

### Weights

Get children with weights
```ruby
unit3.children_weights
# => [[#<Unit id: 5, code: "8">, 5], [#<Unit id: 8, code: "10">, 7]]
```

Parents with weights
```ruby
unit10.parents_weights
# [[#<Unit id: 4, code: "11">, 1], [#<Unit id: 3, code: "3">, 7]]
```

Get all ancestors with weights (split by routes)
```ruby
unit9.ancestors_weights (split by routes)
=> [[[#<Unit id: 1, code: "7">, 4], [#<Unit id: 4, code: "11">, 2]], [[#<Unit id: 1, code: "7">, 1], [#<Unit id: 5, code: "8">, 1]], [[#<Unit id: 2, code: "5">, 6], [#<Unit id: 4, code: "11">, 2]], [[#<Unit id: 3, code: "3">, 5], [#<Unit id: 5, code: "8">, 1]]]
```

Get all descendants with weights (split by routes)
```ruby
uniq5.descendats_weights
# => [[[#<Unit id: 4, code: "11">, 6], [#<Unit id: 7, code: "9">, 2]], [[#<Unit id: 4, code: "11">, 6], [#<Unit id: 8, code: "10">, 1]], [[#<Unit id: 4, code: "11">, 6], [#<Unit id: 6, code: "2">, 9]]]
```

Get all descendants with comprised weights (assembly-like-weight-calculation)
```ruby
unit7.descendants_assembled
# => [[#<Unit id: 4, code: "11">, 4], [#<Unit id: 7, code: "9">, 9], [#<Unit id: 5, code: "8">, 1], [#<Unit id: 8, code: "10">, 4], [#<Unit id: 6, code: "2">, 36]]
```

### Errors

Trying to add node to itself
```ruby
unit3.add_child(unit3)
# => SelfCyclicError: SelfCyclicError
```
Trying to create a loop
```ruby
unit2.add_child(unit7)
# => CyclicError: CyclicError
unit3.add_parent(unit9)
# => CyclicError: CyclicError
```
Trying to duplicate edge
```ruby
unit7.add_child(unit11)
DuplicationError: DuplicationError
unit10.add_parent(unit3)
DuplicationError: DuplicationError
```

### Destroying

Remove a child
```ruby
unit11.children
# => [#<Unit id: 7, code: "9">, #<Unit id: 8, code: "10">, #<Unit id: 6, code: "2">]
unit11.remove_child(unit9)
# => [#<Unit id: 8, code: "10">, #<Unit id: 6, code: "2">]
```
Remove all children
```ruby
unit11.children
# => [#<Unit id: 8, code: "10">, #<Unit id: 6, code: "2">]
unit11.remove_children
# => []
unit11.children
# => []
```
Remove a parent
```ruby
unit8.parents
# => [#<Unit id: 1, code: "7">, #<Unit id: 3, code: "3">]
unit8.remove_parent(unit7)
# => [#<Unit id: 3, code: "3">]
```
Remove all parents
```ruby
unit8.remove_parents
=> []
```

## Methods

method|description
-----|----------
`unit.add_child(another_unit)`| Add `another_unit` as a child node to the `unit`
`unit.add_parent(another_unit)`| Set `another_unit` as a parent node for the `unit`
`unit.parents`|Get all parents of the `unit`
`unit.parents_weights`|Get all parents with weights
`unit.children`|Get all children of the `unit`
`unit.children_weights`|Get all children with weights
`unit.routing` | Get hash of all routes passing the `unit`
`unit.ancestors`| Get array of ancestors of the unit (split by routes)
`unit.self_and_ancetors`| Get array of ancestors including self node (split by routes)
`unit.ancestors_weights`| Get array of ancestors with weights (split by routes)
`unit.descendants`| Get array of descendants of the unit (split by routes)
`unit.self_and_descendants`|Get array of descendants including self node (split by routes)
`unit.descendants_weights`|Get array of descendants with weights (split by routes)
`unit.descendants_assembled`|Get array of descendants with comprised weights (assembly-like-weight-calculation)
`unit.roots`|Get array of root units from ancestors
`unit.leafs`|Get array of leaf units from descendants
`unit.root?` | `true` if unit has no parents
`unit.leaf?` | `true` if unit has no children
`unit.isolated?` | `true` if node has no children no parents
`Unit.roots`|Get array of units without children
`Unit.leafs`|Get array of units without parents

## License
This project rocks and uses MIT-LICENSE.

