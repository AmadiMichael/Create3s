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
| 0                 | 55544          | 91508       |
| 50                | 67092          | 102277      |
| 100               | 78598          | 113158      |
| 150               | 89687          | 124091      |
| 200               | 101217         | 134848      |
| 250               | 112282         | 145765      |
| 300               | 123824         | 156523      |
| 350               | 134877         | 167416      |
| 400               | 146396         | 178162      |
| 450               | 157938         | 189079      |
| 500               | 168979         | 199964      |
| 550               | 180533         | 210742      |
| 600               | 191586         | 221639      |
| 650               | 203128         | 232409      |
| 700               | 214183         | 243304      |
| 750               | 225702         | 254050      |
| 800               | 236779         | 264968      |
| 850               | 248297         | 275714      |
| 900               | 259839         | 286631      |
| 950               | 270893         | 297528      |
| 1000              | 282425         | 308288      |
| 1050              | 293430         | 319134      |
| 1100              | 304984         | 329916      |
| 1150              | 315954         | 340726      |
| 1200              | 327532         | 351532      |
| 1250              | 339088         | 362464      |
| 1300              | 350214         | 373434      |
| 1350              | 361720         | 384165      |
| 1400              | 372737         | 395026      |
| 1450              | 384258         | 405774      |
| 1500              | 395371         | 416729      |
| 1550              | 406853         | 427439      |
| 1600              | 418028         | 438455      |
| 1650              | 429511         | 449166      |
| 1700              | 441030         | 460060      |
| 1750              | 452072         | 470948      |
| 1800              | 463651         | 481755      |
| 1850              | 474693         | 492637      |
| 1900              | 486189         | 503362      |
| 1950              | 497254         | 514268      |
| 2000              | 508786         | 525027      |
| 2050              | 520281         | 535899      |
| 2100              | 531371         | 546834      |
| 2150              | 542915         | 557603      |
| 2200              | 553945         | 568477      |
| 2250              | 565560         | 579320      |
| 2300              | 576507         | 590109      |
| 2350              | 588073         | 600904      |
| 2400              | 599164         | 611837      |
| 2450              | 610683         | 622584      |
| 2500              | 622264         | 633541      |
| 2550              | 633341         | 644463      |
| 2600              | 644874         | 655224      |
| 2650              | 655855         | 666047      |
| 2700              | 667460         | 676881      |
| 2750              | 678526         | 687788      |
| 2800              | 689986         | 698477      |
| 2850              | 701542         | 709408      |
| 2900              | 712656         | 720369      |
| 2950              | 724128         | 731065      |
| 3000              | 735207         | 741990      |
| 3050              | 746715         | 752727      |
| 3100              | 757853         | 763707      |
| 3150              | 769338         | 774420      |
| 3200              | 780403         | 785328      |
| 3250              | 791888         | 796041      |
| 3300              | 803385         | 806915      |
| 3350              | 814498         | 817874      |
| 3400              | 826079         | 828684      |
| 3450              | 837074         | 839522      |
| 3500              | 848619         | 850293      |
| 3550              | 859757         | 861275      |
| 3600              | 871265         | 872011      |
| 3650              | 882750         | 882873      |
| 3700              | 893805         | 893775      |
| 3750              | 905350         | 904545      |
| 3800              | 916500         | 915543      |
| 3850              | 927973         | 926243      |
| 3900              | 939028         | 937141      |
| 3950              | 950621         | 947963      |
