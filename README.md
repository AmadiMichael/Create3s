## Create3s

Cheaper Create3 deployments for small sized contracts (<=3.6KB).

Create3 involves 2 contract deployments and 1 external call while `Create3s` involves only 1 contract deployment and 1 external call but with a couple of transient stores and loads. For small contracts, this is cheaper.

There is also an extra benefit of `getAddressOf` of `Create3s` which is about x2 cheaper than `addressOf` in `Create3`. This should make vanity address generation faster.

### Flow

- User calls `Create3s.create(code, salt)`
- `Create3s` stores `code` in transient storage
- `Create3s` deploys these set of bytes (`5f5f5f5f5f335af1600e575f5ffd5b3d5f5f3e3d5ff3`) via create2 and the `salt` input.
- The deployed bytes calls back into `Create3s` which returns `code` from transient storage.
- The deployed bytes returns `code` as the runtime code of the address.

This way, the salt is the only non-constant determinant of the resultant contract's address.

## Benchmarks

Can reproduce by running `forge test -vvv --mt test_bench_print_create3_and_create3s`

| Code Size (bytes) | `Create3s` Gas | Create3 Gas |
| ----------------- | -------------- | ----------- |
| 0                 | 55559          | 91508       |
| 50                | 67095          | 102265      |
| 100               | 78625          | 113170      |
| 150               | 89702          | 124091      |
| 200               | 101232         | 134848      |
| 250               | 112285         | 145753      |
| 300               | 123815         | 156499      |
| 350               | 134892         | 167416      |
| 400               | 146399         | 178150      |
| 450               | 157941         | 189067      |
| 500               | 169030         | 200000      |
| 550               | 180548         | 210742      |
| 600               | 191613         | 221651      |
| 650               | 203131         | 232397      |
| 700               | 214174         | 243280      |
| 750               | 225717         | 254050      |
| 800               | 236770         | 264944      |
| 850               | 248312         | 275714      |
| 900               | 259818         | 286595      |
| 950               | 270884         | 297504      |
| 1000              | 282440         | 308288      |
| 1050              | 293493         | 319182      |
| 1100              | 305011         | 329928      |
| 1150              | 316113         | 340870      |
| 1200              | 327643         | 351628      |
| 1250              | 339151         | 362512      |
| 1300              | 350229         | 373434      |
| 1350              | 361711         | 384141      |
| 1400              | 372800         | 395074      |
| 1450              | 384345         | 405846      |
| 1500              | 395398         | 416741      |
| 1550              | 406940         | 427511      |
| 1600              | 417959         | 438371      |
| 1650              | 429514         | 449154      |
| 1700              | 441045         | 460060      |
| 1750              | 452135         | 470996      |
| 1800              | 463654         | 481743      |
| 1850              | 474732         | 492661      |
| 1900              | 486180         | 503338      |
| 1950              | 497281         | 514280      |
| 2000              | 508837         | 525063      |
| 2050              | 520344         | 535947      |
| 2100              | 531398         | 546846      |
| 2150              | 542930         | 557603      |
| 2200              | 553972         | 568489      |
| 2250              | 565563         | 579308      |
| 2300              | 576570         | 590157      |
| 2350              | 588112         | 600928      |
| 2400              | 599191         | 611849      |
| 2450              | 610782         | 622668      |
| 2500              | 622231         | 633493      |
| 2550              | 633332         | 644439      |
| 2600              | 644817         | 655152      |
| 2650              | 655906         | 666083      |
| 2700              | 667391         | 676797      |
| 2750              | 678541         | 687788      |
| 2800              | 690037         | 698513      |
| 2850              | 701545         | 709396      |
| 2900              | 712599         | 720297      |
| 2950              | 724191         | 731113      |
| 3000              | 735234         | 742002      |
| 3050              | 746730         | 752727      |
| 3100              | 757736         | 763575      |
| 3150              | 769353         | 774420      |
| 3200              | 780358         | 785268      |
| 3250              | 791927         | 796065      |
| 3300              | 803472         | 806987      |
| 3350              | 814465         | 817826      |
| 3400              | 825998         | 828588      |
| 3450              | 837113         | 839546      |
| 3500              | 848682         | 850341      |
| 3550              | 859760         | 861263      |
| 3600              | 871136         | 871867      |
| 3650              | 882837         | 882945      |
| 3700              | 893808         | 893763      |
| 3750              | 905353         | 904533      |
| 3800              | 916383         | 915411      |
| 3850              | 927964         | 926219      |
| 3900              | 939007         | 937105      |
| 3950              | 950516         | 947843      |
