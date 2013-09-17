Future = Npm.require('fibers/future')


applyUpdate = (collection, selector, modifier) ->
  future = new Future()
  collection.update(
    selector,
    modifier,
    (err, ignored, mongoResult) ->
      if err?
        future['throw'](if err instanceof Error then err else new Error("" + err))
      else
        future['return'](mongoResult)
      return
  )
  future.wait()


delay = (ms) ->
  future = new Future()
  Meteor.setTimeout((-> future['return']()), ms)
  future.wait()


retry = (fn, onFailure) ->
  wait = 0
  for i in [0 ... 10]
    ok = fn()
    return if ok
    delay wait * Math.random()
    wait += 50
  onFailure()
  return


updateUntilCurrent = (collection, selector, updater, onFailure) ->
  if typeof selector is 'string'
    selector = {_id: selector}

  onFailure ?= ->
    throw new Error("timeout attempting to apply atomic update (too much contention)")

  retry(
    (->
      doc = collection.findOne(selector)
      unless doc?
        throw new Error("document not found by selector: " + selector)
      [check, modifier] = updater(doc)
      return applyUpdate(collection, obj(selector, check), modifier) is 1
    ),
    onFailure
  )
  return
