module TwitterCard exposing (TwitterCard, dataSource, view, withLabel)

import DataSource exposing (DataSource)
import DataSource.Http
import Dict exposing (Dict)
import Html
import Html.Attributes
import Html.Parser
import Maybe.Extra
import Pages.Secrets
import Result.Extra
import Url


type alias TwitterCard =
    { url : String
    , labels : List String
    , title : String
    , description : String
    , imageUrl : String
    }


withLabel : String -> TwitterCard -> TwitterCard
withLabel label twitterCard =
    let
        { labels } =
            twitterCard
    in
    { twitterCard
        | labels = label :: labels
    }


parseDocument : String -> String -> Maybe TwitterCard
parseDocument url html =
    case
        Html.Parser.runDocument
            Html.Parser.allCharRefs
            html
    of
        Ok { root } ->
            let
                metaTags =
                    findMetaTags root

                namedMetaTags =
                    getNamedMetaTags metaTags
            in
            parseMetaTags url namedMetaTags

        Err _ ->
            Nothing


findMetaTags : Html.Parser.Node -> List (List ( String, String ))
findMetaTags node =
    case node of
        Html.Parser.Text _ ->
            []

        Html.Parser.Comment _ ->
            []

        Html.Parser.Element "meta" attrs children ->
            [ attrs ] ++ List.concatMap findMetaTags children

        Html.Parser.Element _ _ children ->
            List.concatMap findMetaTags children


{-| Meta tags have this shape:

    [ [ ( "charset", "UTF-8" ) ]
    , [ ( "name", "title" ), ( "content", "My Site" ) ]
    , [ ( "name", "description" ), ( "content", "This site is about..." ) ]
    , ...
    ]

Some of these meta tags have a `name` (or a `property`) attribute with a `content`.

This function filters the named meta tags and saves them in a dict. For example:

    Dict.fromList
        [ ( "title", "My Site" )
        , ( "description", "This site is about..." )
        ]

-}
getNamedMetaTags : List (List ( String, String )) -> Dict String String
getNamedMetaTags metaTags =
    let
        foldFunction metaTag dict =
            case getNameAndContent metaTag of
                Just ( name, content ) ->
                    Dict.insert name content dict

                Nothing ->
                    dict
    in
    List.foldl
        foldFunction
        Dict.empty
        metaTags


getNameAndContent : List ( String, String ) -> Maybe ( String, String )
getNameAndContent metaTag =
    let
        ( maybeName, maybeContent ) =
            getNameAndContentHelp metaTag ( Nothing, Nothing )
    in
    Maybe.map2 Tuple.pair maybeName maybeContent


getNameAndContentHelp : List ( String, String ) -> ( Maybe String, Maybe String ) -> ( Maybe String, Maybe String )
getNameAndContentHelp tag ( maybeName, maybeContent ) =
    case tag of
        ( "name", name ) :: otherAttrs ->
            ( Just name, maybeContent )
                |> getNameAndContentHelp otherAttrs

        ( "property", name ) :: otherAttrs ->
            ( Just name, maybeContent )
                |> getNameAndContentHelp otherAttrs

        ( "content", content ) :: otherAttrs ->
            ( maybeName, Just content )
                |> getNameAndContentHelp otherAttrs

        _ :: otherAttrs ->
            ( maybeName, maybeContent )
                |> getNameAndContentHelp otherAttrs

        [] ->
            ( maybeName, maybeContent )


parseMetaTags : String -> Dict String String -> Maybe TwitterCard
parseMetaTags url metaTags =
    Maybe.map3
        (\title description imageUrl ->
            { url = url
            , labels = []
            , title = title
            , description = description
            , imageUrl = imageUrl
            }
        )
        (Dict.get "twitter:title" metaTags
            |> Maybe.Extra.orElse (Dict.get "og:title" metaTags)
            |> Maybe.Extra.orElse (Dict.get "title" metaTags)
        )
        (Dict.get "twitter:description" metaTags
            |> Maybe.Extra.orElse (Dict.get "og:description" metaTags)
            |> Maybe.Extra.orElse (Dict.get "description" metaTags)
        )
        (Dict.get "twitter:image" metaTags
            |> Maybe.Extra.orElse (Dict.get "og:image" metaTags)
            |> Maybe.Extra.orElse (Dict.get "image" metaTags)
        )



---


dataSource : String -> DataSource TwitterCard
dataSource url =
    DataSource.Http.unoptimizedRequest
        (Pages.Secrets.succeed
            { url = url
            , method = "GET"
            , headers = []
            , body = DataSource.Http.emptyBody
            }
        )
        (DataSource.Http.expectString
            (\htmlString ->
                parseDocument url htmlString
                    |> Result.fromMaybe "Could not parse the twitter card from the HTML"
            )
        )



---


view : TwitterCard -> Html.Html msg
view { url, labels, title, description, imageUrl } =
    let
        parsedUrl =
            Url.fromString url

        viewUrl =
            case parsedUrl of
                Just { host } ->
                    Html.div
                        [ Html.Attributes.class "description" ]
                        [ Html.text host ]

                Nothing ->
                    Html.text ""

        viewTitle =
            Html.div
                [ Html.Attributes.class "title" ]
                [ Html.text title ]

        viewDescription =
            Html.div
                [ Html.Attributes.class "description" ]
                [ Html.text description ]

        viewLabels =
            Html.div
                [ Html.Attributes.class "labels"
                ]
                (Html.text " "
                    :: List.map
                        (\label -> Html.div [] [ Html.text label ])
                        labels
                )

        viewCard =
            Html.a
                [ Html.Attributes.href url
                , Html.Attributes.target "_blank"
                , Html.Attributes.class "twitter-card"
                ]
                [ Html.img [ Html.Attributes.src imageUrl ]
                    []
                , Html.div []
                    [ viewUrl
                    , viewTitle
                    , viewDescription
                    ]
                ]
    in
    Html.div
        [ Html.Attributes.style "display" "flex"
        , Html.Attributes.style "gap" "16px"
        ]
        [ viewLabels
        , viewCard
        ]
