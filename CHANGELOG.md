# Changelog

## [0.6.1](https://github.com/pysan3/tuicrown/compare/v0.6.0...v0.6.1) (2023-05-09)


### Bug Fixes

* **rich:** show auto colorized variables ([e34263c](https://github.com/pysan3/tuicrown/commit/e34263cdb6d27e6e149c3679805420b92e63c723))
* **test:** update correct strings using fgColors ([24f7350](https://github.com/pysan3/tuicrown/commit/24f7350a464e7119b175e5d2ea47ed37ec839c38))
* **variables:** use fgColors to blend in with builtin colors ([6644dc0](https://github.com/pysan3/tuicrown/commit/6644dc0f6bca194027eba5db9abe95acc932d0bd))

## [0.6.0](https://github.com/pysan3/tuicrown/compare/v0.5.1...v0.6.0) (2023-05-09)


### Features

* **segment:** auto colorize variables ([#14](https://github.com/pysan3/tuicrown/issues/14)) ([2a8882b](https://github.com/pysan3/tuicrown/commit/2a8882bc9ef138f6f39110ca713033c17de1e3e3))


### Bug Fixes

* **control:** value shifting is done inside the lib ([dac516c](https://github.com/pysan3/tuicrown/commit/dac516cf61a39de7803e51182bc6aa02e8f56650))
* tuicontrol.nim ([a511d20](https://github.com/pysan3/tuicrown/commit/a511d2030f1b35ca26edd90d1bc7634763888aad))

## [0.5.1](https://github.com/pysan3/tuicrown/compare/v0.5.0...v0.5.1) (2023-05-08)


### Bug Fixes

* **console:** avoid dead lock on multi thread ([e1a7150](https://github.com/pysan3/tuicrown/commit/e1a71507265279154bff4b925db5c66e37e9aff8))

## [0.5.0](https://github.com/pysan3/tuicrown/compare/v0.4.1...v0.5.0) (2023-05-08)


### Features

* rename all exported files ([c183578](https://github.com/pysan3/tuicrown/commit/c183578477981bab3f6cb97e04fd7df6ad38d187))

## [0.4.1](https://github.com/pysan3/tuicrown/compare/v0.4.0...v0.4.1) (2023-05-08)


### Bug Fixes

* **test:** add newline in colormap ([57030c5](https://github.com/pysan3/tuicrown/commit/57030c532f961ab5be93b21d9a56c09ea9ed37d4))

## [0.4.0](https://github.com/pysan3/tuicrown/compare/v0.3.0...v0.4.0) (2023-05-08)


### Features

* **ci:** test with `nim v1.9.3` to check backwards compatibility ([eaf5081](https://github.com/pysan3/tuicrown/commit/eaf508184c881d2000fc94e20bd8790d9f2960b1))
* **docs:** test and docsgen on different ci ([d08d4b2](https://github.com/pysan3/tuicrown/commit/d08d4b28ca3d9c0442cc550e4756d0471aa3cbf2))
* **readme:** add cute badges in readme ([a350cbc](https://github.com/pysan3/tuicrown/commit/a350cbc16ffe77923f09ff06fc2bed54487726b6))
* **refactor:** `src/tuicrown` -&gt; `./tuicrown` ([3a26f7d](https://github.com/pysan3/tuicrown/commit/3a26f7d816087fd8eaf0979c2b636f03f9303076))


### Bug Fixes

* **ci:** do not check for `nim v1.9.x` until it is released ([8924cd6](https://github.com/pysan3/tuicrown/commit/8924cd60d583ba97d8223c36ff68610c32b6e186))
* **ci:** do not run build ([35552a0](https://github.com/pysan3/tuicrown/commit/35552a09042ba9c2333dbdffa57292b22248eda4))
* **ci:** only work on nim-#devel ([8630aaa](https://github.com/pysan3/tuicrown/commit/8630aaa300d0ff725dd22ed99cd57c004dd2b6ac))
* **docs:** do not fail on user input ([d43acf3](https://github.com/pysan3/tuicrown/commit/d43acf314a0a6f1c66683bc8d5d5f98687ae32a4))
* **docs:** fix dependencies and write permissions ([4d763a2](https://github.com/pysan3/tuicrown/commit/4d763a209d64d7478434112b576c57816a3469b4))

## [0.3.0](https://github.com/pysan3/tuicrown/compare/v0.2.0...v0.3.0) (2023-05-08)


### Features

* **release:** auto update nimble package version ([ca4125c](https://github.com/pysan3/tuicrown/commit/ca4125cdf75c4ad8c39c1c069daf0482230c5ad9))


### Bug Fixes

* **release:** check if works without json configs ([25ccd37](https://github.com/pysan3/tuicrown/commit/25ccd374840d9dbf27f7e7042513eb08942ee0e1))
* **release:** version update not working ([d15b3e6](https://github.com/pysan3/tuicrown/commit/d15b3e67f2b4380776a04d8be0b08da6683c6ca5))

## [0.2.0](https://github.com/pysan3/tuicrown/compare/v0.1.0...v0.2.0) (2023-05-08)


### Features

* **readme:** add examples in readme ([c13100c](https://github.com/pysan3/tuicrown/commit/c13100c9da1d514720dfd7123268c7971d3573d3))

## 0.1.0 (2023-05-08)


### Features

* **console:** working console module ([9cec464](https://github.com/pysan3/tuicrown/commit/9cec46431600135a083d2e04c0e4da58528ad70b))
* initilize repo and implement Console ([0080c29](https://github.com/pysan3/tuicrown/commit/0080c29213aab63722d544785b4947305a6ab035))
* **readme:** add install instructions ([c24c8ab](https://github.com/pysan3/tuicrown/commit/c24c8ab57ecb2487fa72cff5bcc4b95a1da10990))
* **segment:** add `print` to generate string ([08bc9d7](https://github.com/pysan3/tuicrown/commit/08bc9d7ae369831b9ae342d980c2fe0df4a0c710))
* **segment:** implement segment class with tests ([17ea184](https://github.com/pysan3/tuicrown/commit/17ea18445563c66dacb22c9c2d97056833fd8f1e))
* **segment:** implement segment parseString ([431170e](https://github.com/pysan3/tuicrown/commit/431170e9f1cf794102d0eca10057c727cea3e47e))
* **test:** add some tests to show rich examples ([db8071b](https://github.com/pysan3/tuicrown/commit/db8071b85f61a0059c0735972f700f44d919d006))


### Miscellaneous Chores

* release 0.0.1 ([65652f5](https://github.com/pysan3/tuicrown/commit/65652f53143b48985fd28cbc370dff27f626a21e))
* release 0.1.0 ([3545fd6](https://github.com/pysan3/tuicrown/commit/3545fd6efad9187a453a70cf6780566afe8251db))
