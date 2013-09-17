updateUntilCurrent = (collection, selector, updater, onFailure) ->
  if typeof selector is 'string'
    selector = {_id: selector}

  doc = collection.findOne(selector)
  unless doc?
    throw new Error("document not found by selector: " + selector)

  [check, modifier] = updater(doc)
  collection.update(obj(selector, check), modifier)

  return
