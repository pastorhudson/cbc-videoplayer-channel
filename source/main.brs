sub main()
    print "################"
    print "Start of Channel"
    print "################"

    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    scene = screen.CreateScene("MainScene")

    ' Create URL transfer object
    ut = CreateObject("roURLTransfer")
    ut.SetPort(m.port)
    ut.SetURL("https://roku.cbcfamily.church")
    ut.SetCertificatesFile("common:/certs/ca-bundle.crt")
    ut.InitClientCertificates()

    print "Fetching feed from https://roku.cbcfamily.church"

    ' Make the request
    if ut.AsyncGetToString() then
        timeout = 10000 ' 10 seconds timeout
        start = CreateObject("roTimespan")

        while true
            msg = wait(100, m.port) ' Check every 100ms

            if msg = invalid
                if start.TotalMilliseconds() > timeout
                    print "Timeout fetching feed"
                    exit while
                end if

            else if type(msg) = "roUrlEvent"
                code = msg.GetResponseCode()
                print "Response received with code: "; code

                if code = 200
                    feedString = msg.GetString()
                    print "Feed length: "; len(feedString)

                    ' Parse the feed
                    feed = ParseJson(feedString)
                    if feed <> invalid
                        ' Debug prints
                        print "Feed parsed successfully"
                        print "Feed keys: "; feed.Keys()
                        if feed.movies <> invalid
                            print "Number of movies: "; feed.movies.Count()
                            if feed.movies.Count() > 0
                                print "First movie title: "; feed.movies[0].title
                                print "First movie content: "; feed.movies[0].content
                            end if
                        end if
                        if feed.liveFeeds <> invalid
                            print "Number of live feeds: "; feed.liveFeeds.Count()
                        end if

                        ' Set the feed to the scene
                        scene.feed = feed
                        print "Feed set to scene"
                    else
                        print "Error parsing feed JSON"
                        print "Raw feed string: "; feedString.Left(500) ' Print first 500 chars
                    end if
                else
                    print "Error fetching feed. Response code: "; code
                end if
                exit while
            end if
        end while
    else
        print "Failed to start feed request"
    end if

    screen.show()
    print "Screen shown"

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed()
                print "Exiting channel"
                return
            end if
        end if
    end while
end sub