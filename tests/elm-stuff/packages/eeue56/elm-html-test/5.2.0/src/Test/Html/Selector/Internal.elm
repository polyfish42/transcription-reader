module Test.Html.Selector.Internal exposing (..)

import ElmHtml.InternalTypes exposing (ElmHtml)
import ElmHtml.Query


type Selector
    = All (List Selector)
    | Classes (List String)
    | Class String
    | Attribute { name : String, value : String }
    | BoolAttribute { name : String, value : Bool }
    | Style (List ( String, String ))
    | Tag String
    | Text String
    | Containing (List Selector)
    | Invalid


selectorToString : Selector -> String
selectorToString criteria =
    case criteria of
        All list ->
            list
                |> List.map selectorToString
                |> String.join " "

        Classes list ->
            "classes " ++ toString (String.join " " list)

        Class class ->
            "class " ++ toString class

        Attribute { name, value } ->
            "attribute "
                ++ toString name
                ++ " "
                ++ toString value

        BoolAttribute { name, value } ->
            "attribute "
                ++ toString name
                ++ " "
                ++ toString value

        Style style ->
            "styles " ++ styleToString style

        Tag name ->
            "tag " ++ toString name

        Text text ->
            "text " ++ toString text

        Containing list ->
            let
                selectors =
                    list
                        |> List.map selectorToString
                        |> String.join ", "
            in
            "containing [ " ++ selectors ++ " ] "

        Invalid ->
            "invalid"


styleToString : List ( String, String ) -> String
styleToString style =
    style
        |> List.map (\( k, v ) -> k ++ ":" ++ v ++ ";")
        |> String.join " "


hasAll : List Selector -> List (ElmHtml msg) -> Bool
hasAll selectors elems =
    case selectors of
        [] ->
            True

        selector :: rest ->
            if List.isEmpty (queryAll [ selector ] elems) then
                False
            else
                hasAll rest elems


queryAll : List Selector -> List (ElmHtml msg) -> List (ElmHtml msg)
queryAll selectors list =
    case selectors of
        [] ->
            list

        selector :: rest ->
            query ElmHtml.Query.query queryAll selector list
                |> queryAll rest


queryAllChildren : List Selector -> List (ElmHtml msg) -> List (ElmHtml msg)
queryAllChildren selectors list =
    case selectors of
        [] ->
            list

        selector :: rest ->
            query ElmHtml.Query.queryChildren queryAllChildren selector list
                |> queryAllChildren rest


query :
    (ElmHtml.Query.Selector -> ElmHtml msg -> List (ElmHtml msg))
    -> (List Selector -> List (ElmHtml msg) -> List (ElmHtml msg))
    -> Selector
    -> List (ElmHtml msg)
    -> List (ElmHtml msg)
query fn fnAll selector list =
    case list of
        [] ->
            list

        elems ->
            case selector of
                All selectors ->
                    fnAll selectors elems

                Classes classes ->
                    List.concatMap (fn (ElmHtml.Query.ClassList classes)) elems

                Class class ->
                    List.concatMap (fn (ElmHtml.Query.ClassList [ class ])) elems

                Attribute { name, value } ->
                    List.concatMap (fn (ElmHtml.Query.Attribute name value)) elems

                BoolAttribute { name, value } ->
                    List.concatMap (fn (ElmHtml.Query.BoolAttribute name value)) elems

                Style style ->
                    List.concatMap (fn (ElmHtml.Query.Style style)) elems

                Tag name ->
                    List.concatMap (fn (ElmHtml.Query.Tag name)) elems

                Text text ->
                    List.concatMap (fn (ElmHtml.Query.ContainsText text)) elems

                Containing selectors ->
                    let
                        anyDescendantsMatch elem =
                            case ElmHtml.Query.getChildren elem of
                                [] ->
                                    -- We have no children;
                                    -- no descendants can possibly match.
                                    False

                                children ->
                                    case query fn fnAll (All selectors) children of
                                        [] ->
                                            -- None of our children matched,
                                            -- but their descendants might!
                                            List.any anyDescendantsMatch children

                                        _ :: _ ->
                                            -- At least one child matched. Yay!
                                            True
                    in
                    List.filter anyDescendantsMatch elems

                Invalid ->
                    []


namedAttr : String -> String -> Selector
namedAttr name value =
    Attribute
        { name = name
        , value = value
        }


namedBoolAttr : String -> Bool -> Selector
namedBoolAttr name value =
    BoolAttribute
        { name = name
        , value = value
        }
