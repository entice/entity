[![Build Status](https://travis-ci.org/entice/entity.svg)](https://travis-ci.org/entice/entity)

Entice.Entity
========

Serves entities. Entities have an ID and can store attributes and behaviours.

=== Entity

An entity is basically a process that consists of state (called attributes) and functionality
(called behaviours).

Example state:

```Elixir
%Entity{
	id: "f089b62f-7f91-40c1-932e-2b152f92e5f1",
	attributes: %{
		SomeAttribute -> %SomeAttribute{...},
		AnotherAttribute -> %AnotherAttribute{...}}}
```

=== Behaviour

Behaviours are the message-handlers of the entity process. This means that any message sent to
the entity is delegated to all behaviours and they are expected to mutate the state of the entity.
Since behaviours are invoked one after another and since they all mutate the same state, you
should make sure that the event handler methods use appropriate matching on the entity state, to
ensure that all attributes you need for your operations are available within the entity.

=== Special Behaviours

The following behaviours are installed in all entities by default (unless you remove them after
entity creation) and usually also have convenience proxy methods within the Entity module.

==== Attribute-Behaviour

This behaviour is mainly used for entity-testing and should usually not be used in production code.
It simplifies interactions with the entitie's state, i.e. you can add and remove attributes with this
more or less directly (via synchroneous message passing).

==== AttributeNotify-Behaviour

This behaviour can be used to observe certain changes within an entity. Essentially you can subscribe
your own process to this behaviour, which will notify you of any added, changed or removed attributes
of an entity, whenever one of these changes happen. Note that you are expected to filter the changes
yourself, so you will also receive changes of attributes that you might not be interested in.

==== Trigger-Behaviour

A trigger is a method that gets an entity passed in, can then trigger side-effects based on this entity,
and returns true or false, based on whether or not it triggered its functionality. Note that if a trigger
returns true, it is assumed to have completed its mission and will be discarded - whereas if it
returns false, it is assumed to not have completed its mission yet and is stored. Stored triggers will be
executed again upon the next entity change. (Essentially triggers are stored and re-executed as long
as they return false)

=== Entity Discovery

(Internally, this uses a trigger) Use this to discovery entities that comply (or not) with certain
standards. E.g. whether or not an entity has a certain attribute. In this case you will be notified
of the entity in question and can then act based on that entities state.
