import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';

/// What each town marker stands in front of.
///
/// **Why this is written down.** The test that used to guard the markers called
/// any six solid tiles a building, and a tree is nine, so a cafe beside an oak
/// and a library on the end of a fence both passed. The second town paints its
/// buildings into the ground layer, where no test of solid tiles can find them.
/// Neither can be fixed by a cleverer flood fill, only by somebody looking at the
/// map, so this is what was seen.
///
/// Each entry is the **tile of the building directly next to the marker** (its
/// door, or the wall the doorstep runs along) and a name for the thing, so a
/// failure can say "the library is not beside the tan hall" and not "(18, 21)".
///
/// **To change one:** render the map with the marker drawn in, look at it,
/// move the marker to the doorstep, and put the door tile here. The recipe is in
/// `tool/README.md`. The tests fail if a marker is not beside its landmark, if
/// the landmark is a tree, a bush or a fence, or if two markers share a building.
typedef Landmark = ({String what, int x, int y});

const Map<TownMap, Map<String, Landmark>>
kTownLandmarks = <TownMap, Map<String, Landmark>>{
  TownMap.village: {
    'spot_campus': (what: 'the north-west brick hall', x: 18, y: 6),
    'spot_bank': (what: 'the north-east brick hall', x: 36, y: 11),
    'spot_pet': (what: 'the small house by the north road', x: 20, y: 11),
    'spot_store': (what: 'the big wooden barn', x: 14, y: 12),
    'spot_market': (what: 'the row of produce stalls', x: 9, y: 9),
    'spot_cafe': (what: 'the bakery with the brick oven', x: 18, y: 21),
    'spot_library': (what: 'the tan rounded hall by the square', x: 30, y: 19),
    'spot_pawn': (what: 'the red-awning stall with the barrels', x: 17, y: 31),
    'spot_clinic': (what: 'the potion shelf beside the school', x: 8, y: 33),
    'spot_school': (what: 'the tall wooden school', x: 11, y: 34),
    'spot_housing': (what: 'the orange cottage on the avenue', x: 28, y: 32),
    'spot_home': (what: 'your own orange cottage', x: 29, y: 43),
    'spot_job': (what: 'the workshop with the water tower', x: 37, y: 35),
    'spot_gym': (what: 'the big orange hall', x: 43, y: 30),
    'spot_notice': (what: 'the notice board by the gym', x: 41, y: 28),
    'spot_park': (what: 'the oak trees by the road', x: 22, y: 34),
  },
  TownMap.market: {
    'spot_campus': (what: 'the brick hall by the east road', x: 41, y: 25),
    'spot_bank': (what: 'the brick town hall', x: 42, y: 9),
    'spot_pet': (what: 'the small red house on the north path', x: 31, y: 6),
    'spot_store': (what: 'the wooden building with the ladders', x: 10, y: 16),
    'spot_market': (
      what: 'the produce table by the general store',
      x: 12,
      y: 4,
    ),
    'spot_cafe': (what: 'the red awning on the south lane', x: 26, y: 41),
    'spot_library': (what: 'the small red house by the field', x: 16, y: 4),
    'spot_pawn': (what: 'the general store with the round window', x: 9, y: 4),
    'spot_clinic': (what: 'the big orange house', x: 18, y: 15),
    'spot_school': (what: 'the tall wooden school', x: 10, y: 32),
    'spot_housing': (
      what: 'the small red house by the playground',
      x: 19,
      y: 19,
    ),
    'spot_home': (what: 'your own orange cottage', x: 43, y: 32),
    'spot_job': (what: 'the workshop with the water tower', x: 40, y: 16),
    'spot_gym': (what: 'the big orange hall with six windows', x: 34, y: 22),
    'spot_notice': (what: 'the notice board by the big hall', x: 31, y: 20),
    'spot_park': (what: 'the playground and its sandpit', x: 24, y: 26),
  },
};
