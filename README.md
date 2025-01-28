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
| 0                 | 55502          | 91488       |
| 50                | 67050          | 102263      |
| 100               | 78556          | 113144      |
| 150               | 89621          | 124047      |
| 200               | 101175         | 134831      |
| 250               | 112240         | 145745      |
| 300               | 123758         | 156485      |
| 350               | 134847         | 167408      |
| 400               | 146353         | 178148      |
| 450               | 157908         | 189077      |
| 500               | 168961         | 199823      |
| 550               | 180479         | 210716      |
| 600               | 191544         | 221619      |
| 650               | 203050         | 232359      |
| 700               | 214152         | 243295      |
| 750               | 225624         | 254000      |
| 800               | 236749         | 264960      |
| 850               | 248279         | 275724      |
| 900               | 259809         | 286629      |
| 950               | 270850         | 297508      |
| 1000              | 282383         | 308271      |
| 1050              | 293436         | 319162      |
| 1100              | 304966         | 329926      |
| 1150              | 316031         | 340826      |
| 1200              | 327550         | 351578      |
| 1250              | 339106         | 362510      |
| 1300              | 350171         | 373269      |
| 1350              | 361702         | 384175      |
| 1400              | 372743         | 395054      |
| 1450              | 384299         | 405844      |
| 1500              | 395388         | 416769      |
| 1550              | 406835         | 427449      |
| 1600              | 417913         | 438362      |
| 1650              | 429457         | 449140      |
| 1700              | 440987         | 460046      |
| 1750              | 452017         | 470915      |
| 1800              | 463621         | 481749      |
| 1850              | 474686         | 492653      |
| 1900              | 486207         | 503408      |
| 1950              | 497224         | 514260      |
| 2000              | 508755         | 525025      |
| 2050              | 520311         | 535957      |
| 2100              | 531352         | 546692      |
| 2150              | 542921         | 557637      |
| 2200              | 553926         | 568481      |
| 2250              | 565434         | 579222      |
| 2300              | 576500         | 590125      |
| 2350              | 588019         | 600878      |
| 2400              | 599073         | 611768      |
| 2450              | 610641         | 622570      |
| 2500              | 622197         | 633503      |
| 2550              | 633275         | 644419      |
| 2600              | 644795         | 655171      |
| 2650              | 655849         | 666063      |
| 2700              | 667417         | 676867      |
| 2750              | 678435         | 687720      |
| 2800              | 690016         | 698535      |
| 2850              | 701523         | 709418      |
| 2900              | 712578         | 720168      |
| 2950              | 724085         | 731051      |
| 3000              | 735188         | 741994      |
| 3050              | 746685         | 752725      |
| 3100              | 757774         | 763651      |
| 3150              | 769247         | 774358      |
| 3200              | 780420         | 785368      |
| 3250              | 791857         | 796039      |
| 3300              | 803366         | 806925      |
| 3350              | 814359         | 817758      |
| 3400              | 825952         | 828582      |
| 3450              | 837031         | 839501      |
| 3500              | 848564         | 850267      |
| 3550              | 859642         | 861183      |
| 3600              | 871210         | 871985      |
| 3650              | 882767         | 882919      |
| 3700              | 893834         | 893681      |
| 3750              | 905367         | 904591      |
| 3800              | 916361         | 915426      |
| 3850              | 927918         | 926217      |
| 3900              | 938949         | 937085      |
| 3950              | 950578         | 947949      |
