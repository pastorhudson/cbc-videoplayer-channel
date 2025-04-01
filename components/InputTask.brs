Sub Init()
    m.top.functionName = "ListenInput"
End Sub

Function ListenInput()
    port = createobject("romessageport")
    InputObject = createobject("roInput")
    InputObject.setmessageport(port)

    while true
      msg = port.waitmessage(500)
      if type(msg) = "roInputEvent" then
        print "INPUT EVENT!"
        if msg.isInput()
          inputData = msg.getInfo()

          ' Print all input parameters for debugging
          print "Input data received:"
          for each key in inputData
            print key + ": " + inputData[key]
          end for

          ' Normalize parameter names for consistency
          ' Handle both contentId and contentID
          deeplink = {}

          if inputData.DoesExist("contentId")
            deeplink.contentId = inputData.contentId
            print "Found contentId: " + deeplink.contentId
          else if inputData.DoesExist("contentID")
            deeplink.contentId = inputData.contentID
            print "Found contentID: " + deeplink.contentId
          end if

          if inputData.DoesExist("mediaType")
            deeplink.mediaType = inputData.mediaType
            print "Found mediaType: " + deeplink.mediaType
          else if inputData.DoesExist("mediatype")
            deeplink.mediaType = inputData.mediatype
            print "Found mediatype: " + deeplink.mediaType
          end if

          ' Handle content_id from the test script
          if inputData.DoesExist("content_id")
            deeplink.contentId = inputData.content_id
            print "Found content_id: " + deeplink.contentId
          end if

          ' Handle media_type from the test script
          if inputData.DoesExist("media_type")
            deeplink.mediaType = inputData.media_type
            print "Found media_type: " + deeplink.mediaType
          end if

          ' Check if it's parsing the test script query properly
          if inputData.DoesExist("query")
            print "Found query: " + inputData.query
            queryParams = parseQueryParams(inputData.query)

            ' Process query parameters
            if queryParams.DoesExist("contentID") and not deeplink.DoesExist("contentId")
              deeplink.contentId = queryParams.contentID
              print "Found contentID in query: " + deeplink.contentId
            end if

            if queryParams.DoesExist("mediatype") and not deeplink.DoesExist("mediaType")
              deeplink.mediaType = queryParams.mediatype
              print "Found mediatype in query: " + deeplink.mediaType
            end if
          end if

          ' Default to "movie" media type if not specified
          if deeplink.DoesExist("contentId") and not deeplink.DoesExist("mediaType")
            deeplink.mediaType = "movie"
            print "No media type specified, defaulting to 'movie'"
          end if

          ' Only pass the data if we have a content ID
          if deeplink.DoesExist("contentId") and deeplink.contentId <> ""
            print "Passing deeplink to UI: "; deeplink
            m.top.inputData = deeplink
          end if
        end if
      end if
    end while
End Function

function parseQueryParams(queryString as String) as Object
    params = CreateObject("roAssociativeArray")

    ' Remove any leading ? if present
    if Left(queryString, 1) = "?"
        queryString = Right(queryString, Len(queryString) - 1)
    end if

    ' Split by & to get parameter pairs
    pairs = queryString.Split("&")
    for each pair in pairs
        ' Split pair by = to get key and value
        keyValue = pair.Split("=")
        if keyValue.Count() = 2
            params[keyValue[0]] = keyValue[1]
        end if
    end for

    return params
end function