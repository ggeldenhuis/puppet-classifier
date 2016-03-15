class classifier (
  Hash[String,
    Struct[{
      match    => Enum["all", "any"],
      rules    => Array[
        Struct[{
          fact     => String,
          operator => Enum["==", "=~", ">", " =>", "<", "<="],
          value    => Data,
          invert   => Optional[Boolean]
        }]
      ],
      data       => Optional[Hash[Pattern[/\A([a-z][a-z0-9_]*)?(::[a-z][a-z0-9_]*)*\Z/], Data]],
      classes    => Array[Pattern[/\A([a-z][a-z0-9_]*)?(::[a-z][a-z0-9_]*)*\Z/]]
    }]
  ] $rules = {},
  Array[Pattern[/\A([a-z][a-z0-9_]*)?(::[a-z][a-z0-9_]*)*\Z/]] $extra_classes = [],
  Boolean $debug = false
) {
  # result of parsing the classification tree
  $classification = classifier::classify($rules)

  if $debug {
    notice("Classification for ${trusted[certname]}: ${classifier::inspect($rules)}")
  }

  $_matched = $classification.filter |$c| { !$c.empty }

  # the classes extracted from the classification
  $classification_classes = $_matched.map |$c| { $c["classes"] }.flatten

  # properties extracted from all the various classifications
  $data = $_matched.reduce({}) |$result, $classification| { $result + $classification["data"] }

  class{"classifier::node_data": data => $data}

  # this should ko merge somehow so that extra_classes can knock out a classified class
  $classes = $classification_classes + $extra_classes

  if $debug {
    notice("Classification result for ${trusted[certname]}: ${classifier::inspect($classification)}")
    notice("Properties derived from classification for ${trusted[certname]}: ${classifier::inspect($data)}")
    notice("Classes derived from classification for ${trusted[certname]}: ${classification_classes}")
    notice("Extra classes declared for ${trusted[certname]}: ${extra_classes}")
    notice("Final classes for ${trusted[certname]}: ${classes}")
  }

  $classes.include
}
