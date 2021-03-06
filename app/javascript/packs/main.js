/* global YT */

import Elm from '../Main'

document.addEventListener('DOMContentLoaded', () => {
  var node = document.getElementById('main')
  var app = Elm.Main.embed(node)

  // Ports

  app.ports.loadVideo.subscribe(function (videoId) {
    loadVideo(videoId)
  })

  app.ports.skipToTime.subscribe(function (time) {
    player.seekTo(time, true)
  })

  // YouTube Player

  var tag = document.createElement('script')

  tag.src = 'https://www.youtube.com/iframe_api'
  var firstScriptTag = document.getElementsByTagName('script')[0]
  firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)

  var player
  const loadVideo = function (videoId) {
    if (player === undefined) {
      player = new YT.Player('player', {
        videoId: videoId,
        host: 'https://www.youtube.com',
        events: {
          'onReady': window.onPlayerReady,
          'onStateChange': window.onPlayerStateChange
        }
      })
    } else {
      player.loadVideoById(videoId)
    }
  }

  window.onYouTubeIframeAPIReady = function () {
    return undefined
  }

  window.onPlayerReady = function (event) {
    event.target.playVideo()
  }

  window.onPlayerStateChange = function (event) {}

  window.stopVideo = function () {
    player.stopVideo()
  }
})
