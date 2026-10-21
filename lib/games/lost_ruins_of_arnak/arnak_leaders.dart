/// Leader tokens from the Expedition Leaders expansions.
class ArnakLeader {
  const ArnakLeader(this.id);

  final String id;

  String get asset => 'assets/games/lost_ruins_of_arnak/leaders/$id.png';

  String get l10nKey => 'arnak.leader.$id';

  static const all = [
    ArnakLeader('captain'),
    ArnakLeader('falconer'),
    ArnakLeader('baroness'),
    ArnakLeader('professor'),
    ArnakLeader('explorer'),
    ArnakLeader('mystic'),
    ArnakLeader('journalist'),
    ArnakLeader('engineer'),
  ];

  static ArnakLeader? byId(String? id) {
    for (final leader in all) {
      if (leader.id == id) {
        return leader;
      }
    }
    return null;
  }
}
