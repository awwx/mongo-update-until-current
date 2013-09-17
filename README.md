# mongo-update-until-current

Advanced atomic updates of Mongo documents using the
[Update if Current](http://docs.mongodb.org/manual/tutorial/isolate-sequence-of-operations/#update-if-current)
pattern, retried until the update can be successfully applied.

Updates of Mongo documents are atomic when the update is entirely
specified by the `modifier` argument of the update method.  For
example, if two methods execute

    collection.update(id, {$inc: {count: 1}});

at the same time, or one method executes

    collection.update(id, {$push: {array: "banana"}});

at the same time as another method executes

    collection.update(id, {$push: {array: "carrot"}});

there's no chance that one of the updates will be lost.  In the first
case, `count` will always be incremented twice, and in the second case
both “banana” and “carrot” will be added to the array.

However, suppose you have an update which is too complicated to be
expressed as a Mongo modifier.  You might want to first read the
document, modify the document yourself, and then write the updated
document to the database:

    var doc = collection.findOne(id);
    // prepend "apple"
    doc.array.splice(0, 0, 'apple');
    collection.update(id, doc);

The problem here is that any other update to the document that happens
between the time of the `findOne` and the `update` will be lost,
overwritten by this update which doesn’t take into account what has
changed.

The [Update if
Current](http://docs.mongodb.org/manual/tutorial/isolate-sequence-of-operations/#update-if-current)
pattern performs the update *only if* the document &mdash; or the part
of the document that is being updated &mdash; hasn’t been changed.
The update is thus only applied if it is valid.

The `updateUntilCurrent` function provided by this package wraps the
Update if Current pattern in a retry loop.  If the first update
doesn’t succeed, it is tried again until it does.

The assumption is that *most* of the time there won’t be contention
for the part of the document which is being updated.  Occasionally,
two methods will perform the update at the same time, one will succeed
and the other fail, and the second will retry and then succeed the
second time.

On the other hand, this isn’t the implementation to use if you do have
many simultaneous updates to the same document.  If that happens,
you’ll want to restructure your data model so that either you are able
to perform your update using just the built-in Mongo modifier
expression language, or so that you don’t have one document that is
“hot” and having many simultaneous updates.

The `updateUntilCurrent` function takes four arguments:

* The collection to perform the atomic update in.

* A [selector](http://docs.meteor.com/#selectors) which matches one
  document in the collection to update.  This can be and often is a
  string, the id of the document.

* An updater function, described below.

* An optional error callback, called if there is too much contention
  and the update could not be applied after multiple retries.  An
  error is thrown if the update can’t be applied and there isn’t an
  error callback.

The updater function takes one argument, the document read using the
passed selector.  It returns two values in an array: a selector to
check whether the relevant part of the document hasn’t changed, and a
modifier to perform the update.

As a simple example, suppose we didn’t have `$inc`, and wanted to
increment a count.

```
updateUntilCurrent(collection, id, function (doc) {
  return [{count: doc.count}, {$set: {count: doc.count + 1}}];
});
```

The first expression is the selector that checks that the `count`
field hasn’t changed, and so we won’t lose anything by setting it
ourselves.  The second expression is a modifier to set the `count`
field to the new value.

For the array prepend example, it would look like this:

```
updateUntilCurrent(collection, id, function (doc) {
  var array = _.clone(doc.array);
  array.splice(0, 0, 'apples');
  return [{array: doc.array}, {$set: {array: array}}];
});
```

Note that we need to clone the array value so that we still have the
original value to use in the selector.


## Install

As of Meteor 0.6.5.1, we need a
[patched version](https://github.com/awwx/meteor-expose-mongo-result#readme)
of Meteor’s mongo-livedata package.

In your Meteor application directory, first create a `packages`
directory if it doesn’t already exist:

    $ mkdir packages

then fetch the patched version of the mongo-livedata package:

    $ git clone https://github.com/awwx/meteor-expose-mongo-result.git -b for-0.6.5.1 packages/mongo-livedata

this will create a `mongo-livedata` directory in your `packages`
directory, which will override the standard Meteor mongo-livedata
package.

To install this mongo-update-until-current package and its other
dependencies, you can use
[Meteorite](http://oortcloud.github.io/meteorite/) as usual:

    $ mrt add mongo-update-until-current


## Donate

An easy and effective way to support the continued maintenance of this
package (and the development of new and useful packages) is to [donate
through Gittip](https://www.gittip.com/awwx/).

Gittip is a [platform for sustainable
crowd-funding](https://www.gittip.com/about/faq.html).

Help build an ecosystem of well maintained, quality Meteor packages by
joining the
[Gittip Meteor Community](https://www.gittip.com/for/meteor/).


## Hire

Need support, debugging, or development for your project?  You can
[hire me](http://awwx.ws/hire-me) to help out.
