Db: require('mongodb/db').Db
ObjectID: require('mongodb/bson/bson').ObjectID
Server: require('mongodb/connection').Server

MessageProvider: (host, port) -> 
  @db: new Db('chat-local', new Server(host, port, {auto_reconnect: true}, {}))
  @db.open(() -> {})
  @db.collection 'messages', (error, message_collection) -> 
    message_collection.ensureIndex([[ 'location', '2d'  ]], () -> {})

MessageProvider::getCollection: (callback) -> 
  @db.collection 'messages', (error, message_collection) ->
    if error 
      callback error
    else 
      callback null, message_collection
      
MessageProvider::getCount: (callback) -> 
  @getCollection (error, message_collection) -> 
    if error
      callback error
    else
      message_collection.count (error, result) ->
        if error 
          callback error
        else 
          callback null, result

MessageProvider::findLocal: (lat, lng, distance, callback) -> 
  @getCollection (error, message_collection) -> 
    if error 
      callback error
    else 
      center: [lat, lng]
      radius: distance / 112.63
      query: {"location" : {"\$within" : {"\$center" : [center, radius]}}}
      orderby: {"_id" : 1 }
      console.log "Querying: " + lat.toString() + " : " + lng.toString() + ", " + distance.toString()
      message_collection.find {"\$query": query, "\$orderby" : orderby}, (error, cursor) -> 
        if error 
          callback error
        else 
          cursor.toArray (error, results) -> 
            if error 
              callback error
            else 
              callback null, results

MessageProvider::save: (messages, callback) ->
  @getCollection (error, message_collection) ->
    if error 
      callback error
    else 
      messages: [messages] unless messages.length?
      message_collection.insert messages, ->
        callback null, messages

exports.MessageProvider: MessageProvider