# Performance Benchmarks

## Description
### Increment Counter (./benchmarks/increment_counter.rb)
Environment:
- 30 concurrent ruby threads
- database pool is 80

```
Rehearsal ---------------------------------------------------
Native Counter   31.589418   2.883422  34.472840 ( 63.833848)
Slotted Counter   8.665961   2.768071  11.434032 ( 12.296364)
----------------------------------------- total: 45.906872sec

                      user     system      total        real
Native Counter   37.597892   3.320797  40.918689 ( 84.823466)
Slotted Counter   9.124994   2.599916  11.724910 ( 13.116726)
```
