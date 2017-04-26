module Element.Style.Sheet exposing (render, renderWith, guard, critical, merge, map, mix)

{-|

@docs render, renderWith, guard, critical, merge, map, mix

-}

import Element.Style.Internal.Model as Internal exposing (StyleSheet)
import Element.Style.Internal.Render as Render
import Element.Style.Internal.Find as Find
import Element.Style.Internal.Batchable as Batchable
import Element.Style.Internal.Intermediate as Intermediate exposing (Rendered(..))
import Element.Style exposing (Style)
import Html.Attributes


type Option class
    = Guard
    | Critical (List class)


{-| -}
type ChildSheet class variation animation
    = ChildSheet (List (Style class variation animation))


{-| -}
guard : Option class
guard =
    Guard


{-| -}
critical : List class -> Option class
critical =
    Critical


{-| -}
render : List (Style class variation animation) -> StyleSheet class variation animation msg
render styles =
    prepareSheet (Render.stylesheet False styles)


{-| -}
renderWith : List (Option class) -> List (Style class variation animation) -> StyleSheet class variation animation msg
renderWith opts styles =
    let
        guard =
            List.any ((==) Guard) opts

        critical =
            List.concatMap criticalClasses opts

        criticalClasses opt =
            case opt of
                Critical class ->
                    class

                _ ->
                    []
    in
        prepareSheet (Render.stylesheet guard styles)


{-| -}
prepareSheet : Intermediate.Rendered class variation animation -> StyleSheet class variation animation msg
prepareSheet (Rendered { css, findable }) =
    let
        variations class vs =
            let
                parent =
                    Find.style class findable

                varys =
                    vs
                        |> List.filter Tuple.second
                        |> List.map ((\vary -> Find.variation class vary findable) << Tuple.first)
                        |> List.map (\cls -> ( cls, True ))
            in
                Html.Attributes.classList (( parent, True ) :: varys)
    in
        { style = \class -> Html.Attributes.class (Find.style class findable)
        , variations = \class varys -> variations class varys
        , animations = []
        , css =
            css
        }


{-| -}
map : (class -> parent) -> List (Style class variation animation) -> ChildSheet parent variation animation
map toParent styles =
    ChildSheet (List.map (Batchable.map (Internal.mapClass toParent)) styles)


{-| Merge a child stylesheet into a parent.
-}
merge : ChildSheet class variation animation -> Style class variation animation
merge (ChildSheet styles) =
    Batchable.many (Batchable.toList styles)


{-| -}
mix : List (Style class variation animation) -> Style class variation animation
mix =
    Batchable.batch
