require 'develop.samples.relations'
require 'develop.samples.systems'

require 'develop.testing.name_tests'
require 'develop.testing.pairs_tests'
require 'develop.testing.requires_fragment_tests'
require 'develop.testing.system_as_query_tests'

require 'develop.untests'

require 'develop.unbench'
require 'develop.usbench'

local basics = require 'develop.basics'

print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.destroy_fuzz'
print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.batch_destroy_fuzz'
print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.explicit_fuzz'
print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.pack_unpack_fuzz'
print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.requires_fuzz'
print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.unique_fuzz'
print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.wildcard_fuzz'
