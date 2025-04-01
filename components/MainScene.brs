sub init()
    print "MainScene - init()"

    ' Initialize UI components
    m.background = m.top.findNode("background")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.videoList = m.top.findNode("videoList")
    m.title = m.top.findNode("titleLabel")
    m.description = m.top.findNode("descriptionLabel")
    m.dateLabel = m.top.findNode("dateLabel")
    m.thumbnailPoster = m.top.findNode("thumbnailPoster")

    ' Store launch args and set up a flag to track deep linking
    m.launchArgs = m.top.launchArgs
    m.deepLinkPending = (m.launchArgs <> invalid)

    ' Debug print launch arguments
    if m.launchArgs <> invalid
        print "Launch arguments received in init:"
        print "ContentId: "; m.launchArgs.contentId
        print "MediaType: "; m.launchArgs.mediaType
    end if

    ' Set up input port
    m.port = CreateObject("roMessagePort")
    m.top.observeField("inputData", m.port)

    ' Observe feed changes
    m.top.observeField("feed", "onFeedChanged")

    ' Check if login is required (add your own logic)
    if isLoginRequired() then
        showLoginDialog()
    end if
end sub

function isLoginRequired() as Boolean
    ' Add your own logic to determine if login is required
    ' For example, check if user credentials are stored
    ' Return true if login is required, false otherwise
    return false ' Default to false for this example
end function

sub showLoginDialog()
    ' Signal that a dialog is about to be displayed
    m.top.signalBeacon("AppDialogInitiate")

    ' Create and show your dialog here
    ' For example:
    ' m.loginDialog = createObject("roSGNode", "Dialog")
    ' m.loginDialog.visible = true
    ' m.loginDialog.observeField("buttonSelected", "onLoginDialogResponse")

    ' Your dialog display code...
end sub

sub onLoginDialogResponse()
    ' Process the dialog response here

    ' Signal that the dialog interaction is complete
    m.top.signalBeacon("AppDialogComplete")

    ' Continue with your application flow
    ' For example:
    ' m.loginDialog.visible = false
    ' loadContent()
end sub

sub onFeedChanged()
    print "MainScene - onFeedChanged called"

    if m.top.feed <> invalid
        print "Feed is valid - loading content"
        loadContent()

        ' Check if we have pending deep link
        if m.deepLinkPending = true
            print "Processing pending deep link"
            checkDeepLink()
            m.deepLinkPending = false
        end if
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
    m.videoList.observeField("itemFocused", "onItemFocused")  ' Change from itemSelected to itemFocused
    m.videoList.observeField("itemSelected", "onItemSelected")
    m.videoList.setFocus(true)
    m.top.signalBeacon("AppLaunchComplete")

    ' Update info for initially focused item
    if m.videoList.content.getChildCount() > 0
        onItemFocused()  ' Update info for the initial item
    end if

    print "Content loading complete"
end sub

sub onItemFocused()
    ' This function will be called whenever the focus changes in the list
    focusedIndex = m.videoList.itemFocused
    updateInfoPanel(focusedIndex)
end sub

sub updateInfoPanel(index as Integer)
    print "Updating info panel for index: "; index

    if index < 0 or m.top.feed = invalid
        return
    end if

    if index = 0 and m.top.feed.liveFeeds <> invalid and m.top.feed.liveFeeds.Count() > 0
        ' Handle live stream selection
        liveFeed = m.top.feed.liveFeeds[0]
        m.title.text = liveFeed.title
        m.description.text = liveFeed.shortDescription
        m.dateLabel.text = "LIVE"

        ' Set thumbnail if available
        if liveFeed.thumbnail <> invalid
            m.thumbnailPoster.uri = liveFeed.thumbnail
        else
            m.thumbnailPoster.uri = "pkg:/images/default-thumbnail.png"
        end if
    else
        ' Handle recorded video selection
        adjustedIndex = index
        if m.top.feed.liveFeeds <> invalid and m.top.feed.liveFeeds.Count() > 0
            adjustedIndex = index - 1 ' Adjust for live stream entry
        end if

        if adjustedIndex >= 0 and adjustedIndex < m.top.feed.movies.Count()
            movie = m.top.feed.movies[adjustedIndex]

            m.title.text = movie.title
            m.description.text = movie.shortDescription
            if movie.releaseDate <> invalid
                m.dateLabel.text = "Date: " + movie.releaseDate
            else
                m.dateLabel.text = ""
            end if

            ' Set thumbnail if available
            if movie.thumbnail <> invalid
                m.thumbnailPoster.uri = movie.thumbnail
                m.thumbnailPoster.visible = true
            else
                m.thumbnailPoster.uri = "pkg:/images/default-thumbnail.png"
                m.thumbnailPoster.visible = true
            end if
        end if
    end if
end sub

sub onItemSelected()
    selectedIndex = m.videoList.itemSelected
    print "Selected index: "; selectedIndex

    if selectedIndex = 0 and m.top.feed.liveFeeds <> invalid and m.top.feed.liveFeeds.Count() > 0
        ' Handle live stream selection
        liveFeed = m.top.feed.liveFeeds[0]
        content = CreateObject("roSGNode", "ContentNode")
        content.streamFormat = "DASH"
        content.url = liveFeed.content.videos[0].url
        m.videoPlayer.content = content
    else
        ' Handle recorded video selection
        adjustedIndex = selectedIndex
        if m.top.feed.liveFeeds <> invalid and m.top.feed.liveFeeds.Count() > 0
            adjustedIndex = selectedIndex - 1 ' Adjust for live stream entry
        end if

        movie = m.top.feed.movies[adjustedIndex]
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
                ' No need to update info panel here as it's already up to date
                return true
            end if
        end if
    end if
    return false
end function

sub checkDeepLink()
    ' Implement deep linking logic here based on m.launchArgs
    if m.launchArgs <> invalid and m.launchArgs.contentId <> invalid
        contentId = m.launchArgs.contentId
        mediaType = m.launchArgs.mediaType

        print "Processing deep link: contentId="; contentId; " mediaType="; mediaType

        ' Add your deep linking implementation here
        ' For example, find the matching content and play it
    end if
end sub