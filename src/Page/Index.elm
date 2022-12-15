module Page.Index exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import DataSource.Http
import Head
import Head.Seo as Seo
import Html
import Html.Attributes
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Secrets
import Pages.Url
import Shared
import TwitterCard exposing (TwitterCard)
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    {}


page : Page RouteParams Data
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildNoState { view = view }


data : DataSource Data
data =
    DataSource.combine
        [ TwitterCard.dataSource "https://medium.com/swlh/what-makes-godot-engine-great-for-advance-gui-applications-b1cfb941df3b"
        , TwitterCard.dataSource "https://felipepepe.medium.com/roblox-is-a-mud-the-history-of-virtual-worlds-muds-mmorpgs-12e41c4cb9b"
        , TwitterCard.dataSource "https://css-tricks.com/equal-columns-with-flexbox-its-more-complicated-than-you-might-think/"
            |> DataSource.map (TwitterCard.withLabel "css")
        ]


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "mauroc8.github.io"
        , image =
            { url = Pages.Url.external ""
            , alt = ""
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "Personal site"
        , locale = Nothing
        , title = "mauroc8 personal site"
        }
        |> Seo.website


type alias Data =
    List TwitterCard.TwitterCard


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = "Saved articles and links - mauroc8.github.io"
    , body =
        [ Html.main_
            [ Html.Attributes.style "display" "flex"
            , Html.Attributes.style "flex-direction" "column"
            , Html.Attributes.style "gap" "24px"
            ]
            (List.map TwitterCard.view static.data)
        ]
    }
