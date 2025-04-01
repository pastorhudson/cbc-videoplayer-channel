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

    ' Set up flags for feed loading and deep linking
    m.feedLoaded = false

    ' Store launch args and set up a flag to track deep linking
    m.launchArgs = m.top.launchArgs
    print "Here's launchArgs"
    print m.launchArgs

    ' Log launch args if available
    if m.launchArgs <> invalid
        print "Launch args in MainScene.init():"
        ' Convert launch args to JSON for clean debugging
        launchArgsJson = FormatJson(m.launchArgs)
        print "Launch args as JSON: " + launchArgsJson
    end if

    ' Create input task for listening to deep link events after launch
    m.inputTask = createObject("roSGNode", "inputTask")
    m.inputTask.observeField("inputData", "onInputDataChanged")
    m.inputTask.control = "RUN"

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

sub onInputDataChanged()
    inputData = m.inputTask.inputData
    print "Received inputData: "; inputData

    if inputData <> invalid
        ' Debug print all fields as JSON
        print "Input data fields:"
        inputDataJson = FormatJson(inputData)
        print "Input data as JSON: " + inputDataJson

        ' Only process if feed is loaded, otherwise store for later
        if m.feedLoaded = true
            print "Feed already loaded - processing deep link immediately"
            processDeepLink(inputData)
        else
            print "Feed not yet loaded - saving deep link for later"
            ' Save as launch args since we use the same mechanism
            m.launchArgs = inputData
        end if
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

        ' Set a flag to indicate feed is loaded
        m.feedLoaded = true

        ' Process any pending deep links
        if m.launchArgs <> invalid
            print "Processing launch arguments after feed loaded"
            print m.launchArgs
            processDeepLink(m.launchArgs)
            m.launchArgs = invalid
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
        liveNode.id = "live"
        ' Don't set mediaType field, it's not supported on ContentNode
        rootNode.appendChild(liveNode)
    end if

    ' Add recorded videos
    if m.top.feed.movies <> invalid
        print "Adding " + str(m.top.feed.movies.Count()) + " movies"
        for each movie in m.top.feed.movies
            videoNode = CreateObject("roSGNode", "ContentNode")
            videoNode.title = movie.title
            videoNode.id = movie.id
            ' Don't set mediaType field, it's not supported on ContentNode
            rootNode.appendChild(videoNode)
            print "Added movie: " + movie.title + " (ID: " + movie.id + ")"
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

    playItemAtIndex(selectedIndex)
end sub

sub playItemAtIndex(selectedIndex as Integer)
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

sub processDeepLink(deepLinkData as Object)
    if deepLinkData = invalid then return

    ' Make sure we have feed data
    if m.top.feed = invalid
        print "ERROR: Cannot process deep link because feed is not loaded yet"
        return
    end if

    ' Print deepLinkData as JSON for debugging
    print "Deep link data received:"
    deepLinkJson = FormatJson(deepLinkData)
    print deepLinkJson

    ' Support both parameter naming conventions
    contentId = invalid
    mediaType = invalid

    ' Helper function to safely get string value
    getStringValue = function(obj as Object, key as String) as Dynamic
        if obj.DoesExist(key)
            value = obj[key]
            valueType = type(value)
            if valueType <> "roString" and valueType <> "String"
                print "Converting " + key + " from " + valueType + " to string"
                return str(value)
            end if
            return value
        end if
        return invalid
    end function

    ' Try all possible content ID keys
    if deepLinkData.DoesExist("contentId")
        contentId = getStringValue(deepLinkData, "contentId")
    else if deepLinkData.DoesExist("contentID")
        contentId = getStringValue(deepLinkData, "contentID")
    else if deepLinkData.DoesExist("content_id")
        contentId = getStringValue(deepLinkData, "content_id")
    end if

    ' Try all possible media type keys
    if deepLinkData.DoesExist("mediaType")
        mediaType = getStringValue(deepLinkData, "mediaType")
    else if deepLinkData.DoesExist("mediatype")
        mediaType = getStringValue(deepLinkData, "mediatype")
    else if deepLinkData.DoesExist("media_type")
        mediaType = getStringValue(deepLinkData, "media_type")
    end if

    print "Processing deep link: contentId="; contentId; " mediaType="; mediaType

    if contentId = invalid
        print "WARNING: No content ID found in deep link"
        return
    end if

    ' Default to "movie" if mediaType is not provided
    if mediaType = invalid
        mediaType = "movie"
        print "No mediaType specified, defaulting to 'movie'"
    end if

    ' Add debugging information
    print "Searching for content with ID: "; contentId
    print "Feed contains "; m.top.feed.movies.Count(); " movies"

    ' Find the content in the feed based on the ID
    if LCase(mediaType) = "live"
        if m.top.feed.liveFeeds <> invalid and m.top.feed.liveFeeds.Count() > 0
            liveFeed = m.top.feed.liveFeeds[0]
            if liveFeed.id = contentId
                ' Play the live stream
                m.videoList.jumpToItem = 0
                playItemAtIndex(0)
            end if
        end if
    else ' Default to movie/video if mediaType isn't specified or is movie/video
        ' Search for the content in the movies list
        if m.top.feed.movies <> invalid
            for i = 0 to m.top.feed.movies.Count() - 1
                print "Checking movie ID: "; m.top.feed.movies[i].id
                if m.top.feed.movies[i].id = contentId
                    ' Calculate the actual index in the list (add 1 if there's a live stream)
                    indexInList = i
                    if m.top.feed.liveFeeds <> invalid and m.top.feed.liveFeeds.Count() > 0
                        indexInList = i + 1
                    end if

                    print "Found matching content at index: "; indexInList
                    ' Play the content immediately
                    playContentDirectly(m.top.feed.movies[i])
                    return
                end if
            end for
            print "WARNING: Could not find content with ID: "; contentId
        end if
    end if
end sub

' New function to play content directly without going through the list selection
sub playContentDirectly(movie as Object)
    if movie = invalid
        print "ERROR: Invalid movie object passed to playContentDirectly"
        return
    end if

    print "Playing content directly: "; movie.title; " (ID: "; movie.id; ")"

    content = CreateObject("roSGNode", "ContentNode")
    content.streamFormat = "DASH"

    ' Make sure the movie has content and videos
    if movie.content <> invalid and movie.content.videos <> invalid and movie.content.videos.Count() > 0
        print "Found video URL: " + movie.content.videos[0].url
        content.url = movie.content.videos[0].url

        ' Set up and play the video
        m.videoPlayer.content = content
        m.videoPlayer.visible = true
        m.videoPlayer.control = "play"
        m.videoPlayer.setFocus(true)

        print "Video playback started directly for: "; movie.title
        print "***** DEEP LINK SUCCESSFUL *****"

        ' Signal deep link success beacon for testing
        m.top.signalBeacon("DeepLinkPlaybackStarted")
    else
        print "ERROR: Could not find video content for movie: "; movie.title
        if movie.content = invalid
            print "movie.content is invalid"
        else if movie.content.videos = invalid
            print "movie.content.videos is invalid"
        else
            print "movie.content.videos count: "; movie.content.videos.Count()
        end if
    end if
end sub