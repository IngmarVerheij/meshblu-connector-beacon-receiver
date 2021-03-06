_              = require 'lodash'
moment         = require 'moment'
{EventEmitter} = require 'events'

class Beacon extends EventEmitter
  constructor: ({ @beacon, @broadcastProximityChange, @broadcastRssiChange, @rssiDelta, @timeout }={}) ->
    @_emit = _.throttle @emit, 500, {leading: true, trailing: false}
    @_initializeGoneInterval()

  initialize: =>
    @_emitData @beacon, true

  close: =>
    clearInterval @_intervalGone
    @beacon.major = -1 # Mark this class for destruction

  isAlive: =>
    return true unless @beacon.major == -1
    return false

  is: (matchBeacon) =>
    { uuid, major, minor } = @beacon
    return false unless matchBeacon.uuid == uuid
    return false unless matchBeacon.major == major
    return false unless matchBeacon.minor == minor
    return true

  _hasProximityChanged: =>
    return false unless @broadcastProximityChange
    return true unless @proximity?
    return true unless @beacon?.proximity?
    @proximity != @beacon.proximity

  _hasRssiChanged: =>
    return false unless @broadcastRssiChange
    return true unless @rssi?
    return true unless @beacon?.rssi?
    ! _.inRange @beacon.rssi, @rssi - @rssiDelta, @rssi + @rssiDelta

  _initializeGoneInterval: =>
    return unless @timeout > 0
    @_intervalGone = setInterval @_checkIfGone, 500

  _checkIfGone: =>
    since = moment().subtract @timeout, 'seconds'
    return if moment(@updatedAt).isAfter since
    defaults =
      proximity: 'gone'
      measuredPower: 0
      rssi: 0
      accuracy: 0
    @_emitData _.defaults defaults, @beacon
    @close()

  update: (@beacon) =>
    return unless @beacon?
    @updatedAt = moment()
    return unless @_hasRssiChanged() || @_hasProximityChanged()
    {@rssi, @proximity} = @beacon
    @_emitData @beacon

  _emitData: (data) =>
    fields = [
      'uuid'
      'major'
      'minor'
      'measuredPower'
      'rssi'
      'accuracy'
      'proximity'
    ]
    @_emit 'data', _.pick data, fields

module.exports = Beacon
