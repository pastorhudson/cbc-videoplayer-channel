sub main()
    print "################"
    print "Start of Channel"
    print "################"

    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    ' Create input object for deep linking
    input = CreateObject("roInput")
    input.SetMessagePort(m.port)

    scene = screen.CreateScene("MainScene")

    ' Create URL transfer object
    ut = CreateObject("roURLTransfer")
    ut.SetPort(m.port)
    ut.SetURL("https://roku.cbcfamily.church/rokufeed")
    ut.SetCertificatesFile("common:/certs/ca-bundle.crt")
    ut.InitClientCertificates()

    print "Fetching feed from https://roku.cbcfamily.church/rokufeed"

    if ut.AsyncGetToString() then
        feedReceived = false
        timeout = 10000 ' 10 seconds timeout
        start = CreateObject("roTimespan")

        screen.show()

        while true
            msg = wait(100, m.port)
            msgType = type(msg)

            if msgType = "roInputEvent" then
                info = msg.GetInfo()
                print "Received input event: "; info

                if info <> invalid and type(info) = "roAssociativeArray" then
                    print "Input info received:"
                    for each key in info
                        print key + ": " + info[key]
                    end for

                    ' Pass launch parameters to scene
                    scene.launchArgs = info
                end if
            else if msgType = "roUrlEvent" and not feedReceived
                code = msg.GetResponseCode()
                print "Response received with code: "; code

                if code = 200
                    feedString = msg.GetString()
                    feed = ParseJson(feedString)

                    if feed <> invalid
                        print "Feed parsed successfully, ensuring thumbnail fields are properly set"

                        ' No need to add or modify thumbnail fields, as they're already in the feed
                        ' and we'll access them directly in MainScene.brs

                        print "Setting feed on scene"
                        scene.feed = feed
                        feedReceived = true
                    else
                        print "Error parsing feed JSON"
                    end if
                else
                    print "Error fetching feed. Response code: "; code
                end if
            else if msgType = "roSGScreenEvent"
                if msg.isScreenClosed()
                    print "Exiting channel"
                    return
                end if
            end if
        end while
    end if
end sub