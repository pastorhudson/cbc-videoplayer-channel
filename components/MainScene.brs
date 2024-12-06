sub init()
    print "MainScene - init()"

    ' Initialize UI components
    m.background = m.top.findNode("background")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.videoList = m.top.findNode("videoList")
    m.title = m.top.findNode("titleLabel")
    m.description = m.top.findNode("descriptionLabel")
    m.dateLabel = m.top.findNode("dateLabel")

    ' Ensure the feed field is properly set up
    if m.top.feed <> invalid
        print "Feed already available at init"
        onFeedChanged()
    else
        print "Waiting for feed..."
    end if

    print "MainScene initialization complete"
end sub

sub onFeedChanged()
    print "MainScene - onFeedChanged called"
    print "Feed value type: "; type(m.top.feed)

    if m.top.feed <> invalid
        print "Feed available - loading content"
        loadContent()
    else
        print "Feed is invalid in onFeedChanged"
    end if
end sub

sub loadContent()
    print "loadContent() started"
    if m.top.feed = invalid
        print "Feed is invalid in loadContent"
        return
    end if

    print "Creating content list..."
    rootNode = CreateObject("roSGNode", "ContentNode")

    ' Add live stream if available
    if m.top.feed.liveFeeds <> invalid and m.top.feed.liveFeeds.Count() > 0
        print "Adding live stream"
        liveNode = CreateObject("roSGNode", "ContentNode")
        liveNode.title = "🔴 " + m.top.feed.liveFeeds[0].title
        rootNode.appendChild(liveNode)
    end if

    ' Add recorded videos
    if m.top.feed.movies <> invalid
        print "Adding " + str(m.top.feed.movies.Count()) + " movies"
        for each movie in m.top.feed.movies
            videoNode = CreateObject("roSGNode", "ContentNode")
            videoNode.title = movie.title
            rootNode.appendChild(videoNode)
            print "Added movie: " + movie.title
        end for
    end if

    print "Setting content to videoList"
    m.videoList.content = rootNode
    m.videoList.observeField("itemSelected", "onItemSelected")
    m.videoList.setFocus(true)

    print "Content loading complete"
end sub

sub onItemSelected()
    selectedIndex = m.videoList.itemSelected
    print "Selected index: "; selectedIndex

    if selectedIndex = 0 and m.top.feed.liveFeeds <> invalid and m.top.feed.liveFeeds.Count() > 0
        ' Handle live stream selection
        liveFeed = m.top.feed.liveFeeds[0]
        m.title.text = liveFeed.title
        m.description.text = liveFeed.shortDescription
        m.dateLabel.text = "LIVE"

        content = CreateObject("roSGNode", "ContentNode")
        content.streamFormat = "DASH"
        content.url = liveFeed.content.videos[0].url
        m.videoPlayer.content = content
    else
        ' Handle recorded video selection
        adjustedIndex = selectedIndex - 1 ' Adjust for live stream entry
        movie = m.top.feed.movies[adjustedIndex]

        m.title.text = movie.title
        m.description.text = movie.shortDescription
        if movie.releaseDate <> invalid
            m.dateLabel.text = "Date: " + movie.releaseDate
        end if

        content = CreateObject("roSGNode", "ContentNode")
        content.streamFormat = "DASH"
        content.url = movie.content.videos[0].url
        m.videoPlayer.content = content
    end if

    ' Show and play video
    m.videoPlayer.visible = true
    m.videoPlayer.control = "play"
    m.videoPlayer.setFocus(true)

    print "Video playback started"
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press
        if key = "back"
            if m.videoPlayer.visible
                m.videoPlayer.control = "stop"
                m.videoPlayer.visible = false
                m.videoList.setFocus(true)
                return true
            end if
        end if
    end if
    return false
end function