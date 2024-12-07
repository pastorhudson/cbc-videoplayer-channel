sub init()
    print "MainScene - init()"

    ' Initialize UI components
    m.background = m.top.findNode("background")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.videoList = m.top.findNode("videoList")
    m.title = m.top.findNode("titleLabel")
    m.description = m.top.findNode("descriptionLabel")
    m.dateLabel = m.top.findNode("dateLabel")

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
end sub


sub checkDeepLink()
    print "Checking deep link arguments..."
    if m.launchArgs = invalid
        print "No launch arguments found"
        return
    end if

    contentId = m.launchArgs.contentId
    mediaType = m.launchArgs.mediaType

    print "Deep link check - ContentId: "; contentId
    print "Deep link check - MediaType: "; mediaType

    ' Check for live stream request
    if contentId = "cbctest3" and mediaType = "live"
        print "Processing cbctest3 live stream request..."

        if m.top.feed = invalid
            print "Error: Feed is not available"
            return
        end if

        if m.top.feed.liveFeeds = invalid
            print "Error: No liveFeeds array in feed"
            return
        end if

        if m.top.feed.liveFeeds.Count() = 0
            print "Error: liveFeeds array is empty"
            return
        end if

        liveFeed = m.top.feed.liveFeeds[0]
        print "Found live feed: "; liveFeed.title

        if liveFeed.content = invalid or liveFeed.content.videos = invalid or liveFeed.content.videos.Count() = 0
            print "Error: Invalid live feed content structure"
            return
        end if

        ' Set up live content
        content = CreateObject("roSGNode", "ContentNode")
        content.streamFormat = "DASH"
        content.url = liveFeed.content.videos[0].url

        print "Live stream URL: "; content.url

        ' Update UI
        m.title.text = liveFeed.title
        m.description.text = liveFeed.shortDescription
        m.dateLabel.text = "LIVE"

        ' Start playback
        m.videoPlayer.content = content
        m.videoPlayer.visible = true
        m.videoPlayer.control = "play"
        m.videoPlayer.setFocus(true)

        print "Live stream playback initiated"
    else
        print "Not a live stream request or unexpected contentId"
    end if
end sub

sub onLaunchArgsChanged()
    print "onLaunchArgsChanged called"
    if m.top.launchArgs <> invalid
        print "Launch args changed:"
        print "ContentId: "; m.top.launchArgs.contentId
        print "MediaType: "; m.top.launchArgs.mediaType

        ' Store launch args
        m.launchArgs = m.top.launchArgs

        ' If feed is already loaded, process deep link immediately
        if m.top.feed <> invalid
            print "Feed already loaded, processing deep link immediately"
            checkDeepLink()
        else
            print "Feed not yet loaded, deep link will be processed when feed arrives"
        end if
    end if
end sub

sub startInputMonitoring()
    print "Starting input monitoring loop"
    m.inputMonitoringActive = true

    while m.inputMonitoringActive
        msg = wait(0, m.port)
        msgType = type(msg)

        if msgType = "roInputEvent"
            handleInputEvent(msg)
        else if msgType = "roSGNodeEvent"
            if msg.getField() = "inputData"
                handleInputData(msg.getData())
            end if
        end if
    end while
end sub

sub handleInputEvent(event as Object)
    print "Handling input event"
    if event.isInput()
        inputData = event.getData()
        ' Process input data based on your requirements
        if inputData <> invalid
            if inputData.DoesExist("type")
                inputType = inputData.type

                if inputType = "voice"
                    handleVoiceCommand(inputData)
                else if inputType = "deeplink"
                    handleDeepLink(inputData)
                end if
            end if
        end if
    end if
end sub

sub handleInputData(data as Object)
    print "Processing input data: "; data
    if data <> invalid
        if data.DoesExist("command")
            command = data.command

            if command = "play"
                if m.videoPlayer.visible
                    m.videoPlayer.control = "play"
                else
                    ' Auto-play first item if nothing is playing
                    if m.videoList.content <> invalid and m.videoList.content.getChildCount() > 0
                        m.videoList.itemSelected = 0
                        onItemSelected()
                    end if
                end if
            else if command = "pause"
                if m.videoPlayer.visible
                    m.videoPlayer.control = "pause"
                end if
            else if command = "search"
                if data.DoesExist("term")
                    performSearch(data.term)
                end if
            end if
        end if
    end if
end sub

sub handleVoiceCommand(inputData as Object)
    print "Processing voice command"
    if inputData.DoesExist("query")
        query = inputData.query
        ' Implement voice command logic here
        ' Example: Search for content, navigate to specific sections, etc.
        performSearch(query)
    end if
end sub

sub handleDeepLink(inputData as Object)
    print "Processing deep link"
    if inputData.DoesExist("contentId")
        contentId = inputData.contentId
        ' Implement deep linking logic here
        ' Example: Jump to specific content, category, etc.
        playContentById(contentId)
    end if
end sub

sub performSearch(searchTerm as String)
    print "Performing search for: "; searchTerm
    ' Implement search functionality
    if m.top.feed <> invalid and m.top.feed.movies <> invalid
        searchResults = []
        searchTerm = LCase(searchTerm)

        for each movie in m.top.feed.movies
            if LCase(movie.title).Instr(searchTerm) >= 0
                searchResults.Push(movie)
            end if
        end for

        updateSearchResults(searchResults)
    end if
end sub

sub playContentById(contentId as String)
    print "Playing content with ID: "; contentId
    if m.top.feed <> invalid and m.top.feed.movies <> invalid
        for i = 0 to m.top.feed.movies.Count() - 1
            if m.top.feed.movies[i].id = contentId
                m.videoList.itemSelected = i
                onItemSelected()
                exit for
            end if
        end for
    end if
end sub

sub updateSearchResults(results as Object)
    print "Updating search results"
    if results <> invalid
        rootNode = CreateObject("roSGNode", "ContentNode")

        for each result in results
            videoNode = CreateObject("roSGNode", "ContentNode")
            videoNode.title = result.title
            rootNode.appendChild(videoNode)
        end for

        m.videoList.content = rootNode
        m.videoList.setFocus(true)
    end if
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
    m.videoList.observeField("itemSelected", "onItemSelected")
    m.videoList.setFocus(true)
    m.top.signalBeacon("AppLaunchComplete")
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