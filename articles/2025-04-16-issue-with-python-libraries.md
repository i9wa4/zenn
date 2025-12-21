---
title: "Python でありがちな本体バージョンとライブラリバージョンの不整合の例"
emoji: "🐴"
type: "tech" # tech: 技術記事 / idea: アイデア
topics:
  - "python"
published: true
publication_name: "genda_jp"
---

## 1. はじめに

ライブラリのバージョンを固定した上で最新のバージョンの Python を使おうとすると色々とエラーが発生しがちです。

直近遭遇したエラーを記録に残しておきます。

## 2. 背景

dbt-databricks==1.7.17 のインストールを試みました。

本来は最新バージョンをインストールすべきで、執筆時点では 1.10.0 です。
このコマンドを知らなかったのでメモ代わりに残しておきます。

```bash
$ pip index versions dbt-databricks
WARNING: pip index is currently an experimental command. It may be removed/changed in a future release without prior warning.
dbt-databricks (1.10.0)
Available versions: 1.10.0, 1.9.7, 1.9.6, 1.9.5, 1.9.4, 1.9.2, 1.9.1, 1.9.0, 1.8.7, 1.8.6, 1.8.5, 1.8.4, 1.8.3, 1.8.2, 1.8.1, 1.8.0, 1.7.17, 1.7.16, 1.7.15, 1.7.14, 1.7.13, 1.7.11, 1.7.10, 1.7.9, 1.7.8, 1.7.7, 1.7.3, 1.7.2, 1.7.1, 1.7.0, 1.6.9, 1.6.8, 1.6.7, 1.6.6, 1.6.5, 1.6.4, 1.6.3, 1.6.2, 1.6.1, 1.6.0, 1.5.7, 1.5.6, 1.5.5, 1.5.4, 1.5.3, 1.5.2, 1.5.1, 1.5.0, 1.4.3, 1.4.2, 1.4.1, 1.4.0, 1.3.2, 1.3.1, 1.3.0, 1.2.5, 1.2.4, 1.2.3, 1.2.2, 1.2.1, 1.2.0, 1.1.7, 1.1.6, 1.1.5, 1.1.4, 1.1.3, 1.1.2, 1.1.1, 1.1.0, 1.0.3, 1.0.2, 1.0.1, 1.0.0, 0.21.1
```

以下では Python 3.13 と 3.12 の両方で試してみます。

## 3. Python 3.13.3 との相性

::: details エラーログ詳細

```bash
$ python --version
Python 3.13.3

$ python -m venv my-venv-3.13.3

$ source my-venv-3.13.3/bin/activate
(my-venv-3.13.3)
$ pip install dbt-databricks==1.7.17
Collecting dbt-databricks==1.7.17
  Using cached dbt_databricks-1.7.17-py3-none-any.whl.metadata (5.6 kB)
Collecting dbt-spark~=1.7.1 (from dbt-databricks==1.7.17)
  Using cached dbt_spark-1.7.1-py3-none-any.whl.metadata (5.3 kB)
Collecting databricks-sql-connector<3.0.0,>=2.9.3 (from dbt-databricks==1.7.17)
  Using cached databricks_sql_connector-2.9.6-py3-none-any.whl.metadata (4.3 kB)
Collecting databricks-sdk==0.17.0 (from dbt-databricks==1.7.17)
  Using cached databricks_sdk-0.17.0-py3-none-any.whl.metadata (34 kB)
Collecting keyring>=23.13.0 (from dbt-databricks==1.7.17)
  Using cached keyring-25.6.0-py3-none-any.whl.metadata (20 kB)
Collecting pandas<2.2.0 (from dbt-databricks==1.7.17)
  Using cached pandas-2.1.4.tar.gz (4.3 MB)
  Installing build dependencies ... done
  Getting requirements to build wheel ... done
  Preparing metadata (pyproject.toml) ... error
  error: subprocess-exited-with-error

  × Preparing metadata (pyproject.toml) did not run successfully.
  │ exit code: 1
  ╰─> [115 lines of output]
      + meson setup /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88 /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/.mesonpy-iz9fcfer/build -Dbuildtype=release -Db_ndebug=if-release -Db_vscrt=md --vsenv --native-file=/private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/.mesonpy-iz9fcfer/build/meson-python-native-file.ini
      The Meson build system
      Version: 1.2.1
      Source dir: /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88
      Build dir: /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/.mesonpy-iz9fcfer/build
      Build type: native build
      Project name: pandas
      Project version: 2.1.4
      C compiler for the host machine: cc (clang 17.0.0 "Apple clang version 17.0.0 (clang-1700.0.13.3)")
      C linker for the host machine: cc ld64 1167.4.1
      C++ compiler for the host machine: c++ (clang 17.0.0 "Apple clang version 17.0.0 (clang-1700.0.13.3)")
      C++ linker for the host machine: c++ ld64 1167.4.1
      Cython compiler for the host machine: cython (cython 0.29.37)
      Host machine cpu family: aarch64
      Host machine cpu: aarch64
      Program python found: YES (/Users/uma-chan/.venv/my-venv-3.13.3/bin/python)
      Did not find pkg-config by name 'pkg-config'
      Found Pkg-config: NO
      Run-time dependency python found: YES 3.13
      Build targets in project: 53

      pandas 2.1.4

        User defined options
          Native files: /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/.mesonpy-iz9fcfer/build/meson-python-native-file.ini
          buildtype   : release
          vsenv       : True
          b_ndebug    : if-release
          b_vscrt     : md

      Found ninja-1.12.1 at /opt/homebrew/bin/ninja

      Visual Studio environment is needed to run Ninja. It is recommended to use Meson wrapper:
      /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-build-env-i26gzs0z/overlay/bin/meson compile -C .
      + /opt/homebrew/bin/ninja
      [1/151] Generating pandas/_libs/index_class_helper_pxi with a custom command
      [2/151] Generating pandas/_libs/hashtable_class_helper_pxi with a custom command
      [3/151] Generating pandas/_libs/algos_common_helper_pxi with a custom command
      [4/151] Generating pandas/_libs/algos_take_helper_pxi with a custom command
      [5/151] Generating pandas/_libs/intervaltree_helper_pxi with a custom command
      [6/151] Generating pandas/_libs/hashtable_func_helper_pxi with a custom command
      [7/151] Generating pandas/_libs/khash_primitive_helper_pxi with a custom command
      [8/151] Generating pandas/_libs/sparse_op_helper_pxi with a custom command
      [9/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/base.pyx
      [10/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/ccalendar.pyx
      [11/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/dtypes.pyx
      [12/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/np_datetime.pyx
      [13/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/nattype.pyx
      [14/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/conversion.pyx
      [15/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/strptime.pyx
      [16/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/fields.pyx
      [17/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/parsing.pyx
      [18/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/offsets.pyx
      [19/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/timezones.pyx
      [20/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/timedeltas.pyx
      [21/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/period.pyx
      [22/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/vectorized.pyx
      [23/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/tzconversion.pyx
      [24/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/indexing.pyx
      [25/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/arrays.pyx
      [26/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslibs/timestamps.pyx
      [27/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/missing.pyx
      [28/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/hashing.pyx
      [29/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/ops_dispatch.pyx
      [30/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/properties.pyx
      [31/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/ops.pyx
      [32/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/internals.pyx
      [33/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/byteswap.pyx
      [34/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/parsers.pyx
      [35/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/index.pyx
      [36/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/sas.pyx
      [37/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/lib.pyx
      [38/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/reshape.pyx
      [39/151] Compiling C object pandas/_libs/tslibs/base.cpython-313-darwin.so.p/meson-generated_pandas__libs_tslibs_base.pyx.c.o
      FAILED: pandas/_libs/tslibs/base.cpython-313-darwin.so.p/meson-generated_pandas__libs_tslibs_base.pyx.c.o
      cc -Ipandas/_libs/tslibs/base.cpython-313-darwin.so.p -Ipandas/_libs/tslibs -I../../pandas/_libs/tslibs -I../../../../pip-build-env-i26gzs0z/overlay/lib/python3.13/site-packages/numpy/core/include -I../../pandas/_libs/include -I/Users/uma-chan/.pyenv/versions/3.13.3/include/python3.13 -fvisibility=hidden -fcolor-diagnostics -DNDEBUG -w -std=c99 -O3 -DNPY_NO_DEPRECATED_API=0 -DNPY_TARGET_VERSION=NPY_1_21_API_VERSION -MD -MQ pandas/_libs/tslibs/base.cpython-313-darwin.so.p/meson-generated_pandas__libs_tslibs_base.pyx.c.o -MF pandas/_libs/tslibs/base.cpython-313-darwin.so.p/meson-generated_pandas__libs_tslibs_base.pyx.c.o.d -o pandas/_libs/tslibs/base.cpython-313-darwin.so.p/meson-generated_pandas__libs_tslibs_base.pyx.c.o -c pandas/_libs/tslibs/base.cpython-313-darwin.so.p/pandas/_libs/tslibs/base.pyx.c
      pandas/_libs/tslibs/base.cpython-313-darwin.so.p/pandas/_libs/tslibs/base.pyx.c:5399:70: error: too few arguments to function call, expected 6, have 5
       5397 |                 int ret = _PyLong_AsByteArray((PyLongObject *)v,
            |                           ~~~~~~~~~~~~~~~~~~~
       5398 |                                               bytes, sizeof(val),
       5399 |                                               is_little, !is_unsigned);
            |                                                                      ^
      /Users/uma-chan/.pyenv/versions/3.13.3/include/python3.13/cpython/longobject.h:111:17: note: '_PyLong_AsByteArray' declared here
        111 | PyAPI_FUNC(int) _PyLong_AsByteArray(PyLongObject* v,
            |                 ^                   ~~~~~~~~~~~~~~~~
        112 |     unsigned char* bytes, size_t n,
            |     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        113 |     int little_endian, int is_signed, int with_exceptions);
            |     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      pandas/_libs/tslibs/base.cpython-313-darwin.so.p/pandas/_libs/tslibs/base.pyx.c:5633:70: error: too few arguments to function call, expected 6, have 5
       5631 |                 int ret = _PyLong_AsByteArray((PyLongObject *)v,
            |                           ~~~~~~~~~~~~~~~~~~~
       5632 |                                               bytes, sizeof(val),
       5633 |                                               is_little, !is_unsigned);
            |                                                                      ^
      /Users/uma-chan/.pyenv/versions/3.13.3/include/python3.13/cpython/longobject.h:111:17: note: '_PyLong_AsByteArray' declared here
        111 | PyAPI_FUNC(int) _PyLong_AsByteArray(PyLongObject* v,
            |                 ^                   ~~~~~~~~~~~~~~~~
        112 |     unsigned char* bytes, size_t n,
            |     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        113 |     int little_endian, int is_signed, int with_exceptions);
            |     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      2 errors generated.
      [40/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/testing.pyx
      [41/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/tslib.pyx
      [42/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/interval.pyx
      [43/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/writers.pyx
      [44/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/window/indexers.pyx
      [45/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/window/aggregations.pyx
      [46/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/algos.pyx
      [47/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/hashtable.pyx
      [48/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/sparse.pyx
      [49/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/join.pyx
      [50/151] Compiling Cython source /private/var/folders/xc/_1gjnwkd25j8hynw16xskg3r0000gn/T/pip-install-glb02n1x/pandas_d6eab0be3ccb474ba209bf6b5865cf88/pandas/_libs/groupby.pyx
      ninja: build stopped: subcommand failed.
      [end of output]

  note: This error originates from a subprocess, and is likely not a problem with pip.
error: metadata-generation-failed

× Encountered error while generating package metadata.
╰─> See above for output.

note: This is an issue with the package mentioned above, not pip.
hint: See above for details.
(my-venv-3.13.3)
$
```

:::

以下、エラー原因を追跡します。

執筆時点では Pandas の最新バージョンは 2.2.3 なのですが dbt-databricks のバージョンを固定したことで 2.2.0 未満をインストールするようになっています。
そして 2.1.4 をインストールすることになります。

> ```bash
> Collecting pandas<2.2.0 (from dbt-databricks==1.7.17)
> ```

Pandas 2.2.3 では Python 3.13 用の wheel が用意されているのですが 2.1.4 時点では用意されておらず Pandas をソースコードからビルドしようとします。

しかし Pandas 2.1.4 のビルドに利用している関数が Python 3.13.0 では削除されてしまったためビルドに失敗します。

> ```bash
>       pandas/_libs/tslibs/base.cpython-313-darwin.so.p/pandas/_libs/tslibs/base.pyx.c:5399:70: error: too few arguments to function call, expected 6, have 5
>        5397 |                 int ret = _PyLong_AsByteArray((PyLongObject *)v,
>             |                           ~~~~~~~~~~~~~~~~~~~
>        5398 |                                               bytes, sizeof(val),
>        5399 |                                               is_little, !is_unsigned);
>             |                                                                      ^
> ```

Pandas 側の Issue:

@[card](https://github.com/pandas-dev/pandas/issues/58734)

CPython 側の Pull Request:

@[card](https://github.com/python/cpython/pull/108429)

というわけで dbt-databricks==1.7.17 と Python 3.13 は相性が悪いということになります。

## 4. Python 3.12.10 との相性

::: details ログ詳細

```bash
$ python --version
Python 3.12.10

$ python -m venv my-venv-3.12.10

$ source my-venv-3.12.10/bin/activate
((my-venv-3.12.10) )
$ pip install dbt-databricks==1.7.17
Collecting dbt-databricks==1.7.17
  Using cached dbt_databricks-1.7.17-py3-none-any.whl.metadata (5.6 kB)
Collecting dbt-spark~=1.7.1 (from dbt-databricks==1.7.17)
  Using cached dbt_spark-1.7.1-py3-none-any.whl.metadata (5.3 kB)
Collecting databricks-sql-connector<3.0.0,>=2.9.3 (from dbt-databricks==1.7.17)
  Using cached databricks_sql_connector-2.9.6-py3-none-any.whl.metadata (4.3 kB)
Collecting databricks-sdk==0.17.0 (from dbt-databricks==1.7.17)
  Using cached databricks_sdk-0.17.0-py3-none-any.whl.metadata (34 kB)
Collecting keyring>=23.13.0 (from dbt-databricks==1.7.17)
  Using cached keyring-25.6.0-py3-none-any.whl.metadata (20 kB)
Collecting pandas<2.2.0 (from dbt-databricks==1.7.17)
  Using cached pandas-2.1.4-cp312-cp312-macosx_11_0_arm64.whl.metadata (18 kB)
Collecting protobuf<5.0.0 (from dbt-databricks==1.7.17)
  Using cached protobuf-4.25.6-cp37-abi3-macosx_10_9_universal2.whl.metadata (541 bytes)
Collecting google-auth~=2.0 (from databricks-sdk==0.17.0->dbt-databricks==1.7.17)
  Using cached google_auth-2.39.0-py2.py3-none-any.whl.metadata (6.2 kB)
Collecting requests<3,>=2.28.1 (from databricks-sdk==0.17.0->dbt-databricks==1.7.17)
  Using cached requests-2.32.3-py3-none-any.whl.metadata (4.6 kB)
Collecting alembic<2.0.0,>=1.0.11 (from databricks-sql-connector<3.0.0,>=2.9.3->dbt-databricks==1.7.17)
  Using cached alembic-1.15.2-py3-none-any.whl.metadata (7.3 kB)
Collecting lz4<5.0.0,>=4.0.2 (from databricks-sql-connector<3.0.0,>=2.9.3->dbt-databricks==1.7.17)
  Using cached lz4-4.4.4-cp312-cp312-macosx_11_0_arm64.whl.metadata (3.8 kB)
Collecting numpy>=1.23.4 (from databricks-sql-connector<3.0.0,>=2.9.3->dbt-databricks==1.7.17)
  Using cached numpy-2.2.4-cp312-cp312-macosx_14_0_arm64.whl.metadata (62 kB)
Collecting oauthlib<4.0.0,>=3.1.0 (from databricks-sql-connector<3.0.0,>=2.9.3->dbt-databricks==1.7.17)
  Using cached oauthlib-3.2.2-py3-none-any.whl.metadata (7.5 kB)
Collecting openpyxl<4.0.0,>=3.0.10 (from databricks-sql-connector<3.0.0,>=2.9.3->dbt-databricks==1.7.17)
  Using cached openpyxl-3.1.5-py2.py3-none-any.whl.metadata (2.5 kB)
Collecting pyarrow>=10.0.1 (from databricks-sql-connector<3.0.0,>=2.9.3->dbt-databricks==1.7.17)
  Using cached pyarrow-19.0.1-cp312-cp312-macosx_12_0_arm64.whl.metadata (3.3 kB)
Collecting sqlalchemy<2.0.0,>=1.3.24 (from databricks-sql-connector<3.0.0,>=2.9.3->dbt-databricks==1.7.17)
  Using cached SQLAlchemy-1.4.54-cp312-cp312-macosx_10_9_universal2.whl.metadata (10 kB)
Collecting thrift<0.17.0,>=0.16.0 (from databricks-sql-connector<3.0.0,>=2.9.3->dbt-databricks==1.7.17)
  Using cached thrift-0.16.0-cp312-cp312-macosx_15_0_arm64.whl
Collecting urllib3>=1.0 (from databricks-sql-connector<3.0.0,>=2.9.3->dbt-databricks==1.7.17)
  Using cached urllib3-2.4.0-py3-none-any.whl.metadata (6.5 kB)
Collecting dbt-core~=1.7.0 (from dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Downloading dbt_core-1.7.19-py3-none-any.whl.metadata (3.9 kB)
Collecting sqlparams>=3.0.0 (from dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached sqlparams-6.2.0-py3-none-any.whl.metadata (8.8 kB)
Collecting jaraco.classes (from keyring>=23.13.0->dbt-databricks==1.7.17)
  Using cached jaraco.classes-3.4.0-py3-none-any.whl.metadata (2.6 kB)
Collecting jaraco.functools (from keyring>=23.13.0->dbt-databricks==1.7.17)
  Using cached jaraco.functools-4.1.0-py3-none-any.whl.metadata (2.9 kB)
Collecting jaraco.context (from keyring>=23.13.0->dbt-databricks==1.7.17)
  Using cached jaraco.context-6.0.1-py3-none-any.whl.metadata (4.1 kB)
Collecting numpy>=1.23.4 (from databricks-sql-connector<3.0.0,>=2.9.3->dbt-databricks==1.7.17)
  Using cached numpy-1.26.4-cp312-cp312-macosx_11_0_arm64.whl.metadata (61 kB)
Collecting python-dateutil>=2.8.2 (from pandas<2.2.0->dbt-databricks==1.7.17)
  Using cached python_dateutil-2.9.0.post0-py2.py3-none-any.whl.metadata (8.4 kB)
Collecting pytz>=2020.1 (from pandas<2.2.0->dbt-databricks==1.7.17)
  Using cached pytz-2025.2-py2.py3-none-any.whl.metadata (22 kB)
Collecting tzdata>=2022.1 (from pandas<2.2.0->dbt-databricks==1.7.17)
  Using cached tzdata-2025.2-py2.py3-none-any.whl.metadata (1.4 kB)
Collecting Mako (from alembic<2.0.0,>=1.0.11->databricks-sql-connector<3.0.0,>=2.9.3->dbt-databricks==1.7.17)
  Using cached mako-1.3.10-py3-none-any.whl.metadata (2.9 kB)
Collecting typing-extensions>=4.12 (from alembic<2.0.0,>=1.0.11->databricks-sql-connector<3.0.0,>=2.9.3->dbt-databricks==1.7.17)
  Using cached typing_extensions-4.13.2-py3-none-any.whl.metadata (3.0 kB)
Collecting agate~=1.7.0 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached agate-1.7.1-py2.py3-none-any.whl.metadata (3.1 kB)
Collecting Jinja2<4,>=3.1.3 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached jinja2-3.1.6-py3-none-any.whl.metadata (2.9 kB)
Collecting mashumaro<3.15,>=3.9 (from mashumaro[msgpack]<3.15,>=3.9->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Downloading mashumaro-3.14-py3-none-any.whl.metadata (114 kB)
Collecting logbook<1.6,>=1.5 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached logbook-1.5.3-cp312-cp312-macosx_15_0_arm64.whl
Collecting click<9,>=8.0.2 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached click-8.1.8-py3-none-any.whl.metadata (2.3 kB)
Collecting networkx<4,>=2.3 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached networkx-3.4.2-py3-none-any.whl.metadata (6.3 kB)
Collecting colorama<0.5,>=0.3.9 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached colorama-0.4.6-py2.py3-none-any.whl.metadata (17 kB)
Collecting pathspec<0.12,>=0.9 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached pathspec-0.11.2-py3-none-any.whl.metadata (19 kB)
Collecting isodate<0.7,>=0.6 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached isodate-0.6.1-py2.py3-none-any.whl.metadata (9.6 kB)
Collecting sqlparse<0.6.0,>=0.5.0 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Downloading sqlparse-0.5.3-py3-none-any.whl.metadata (3.9 kB)
Collecting dbt-extractor~=0.5.0 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached dbt_extractor-0.5.1-cp38-abi3-macosx_10_12_x86_64.macosx_11_0_arm64.macosx_10_12_universal2.whl.metadata (4.2 kB)
Collecting minimal-snowplow-tracker~=0.0.2 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached minimal_snowplow_tracker-0.0.2-py3-none-any.whl
Collecting dbt-semantic-interfaces~=0.4.2 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached dbt_semantic_interfaces-0.4.4-py3-none-any.whl.metadata (2.5 kB)
Collecting jsonschema>=3.0 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached jsonschema-4.23.0-py3-none-any.whl.metadata (7.9 kB)
Collecting packaging>20.9 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached packaging-24.2-py3-none-any.whl.metadata (3.2 kB)
Collecting pyyaml>=6.0 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached PyYAML-6.0.2-cp312-cp312-macosx_11_0_arm64.whl.metadata (2.1 kB)
Collecting cffi<2.0.0,>=1.9 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached cffi-1.17.1-cp312-cp312-macosx_11_0_arm64.whl.metadata (1.5 kB)
Collecting idna<4,>=2.5 (from dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached idna-3.10-py3-none-any.whl.metadata (10 kB)
Collecting urllib3>=1.0 (from databricks-sql-connector<3.0.0,>=2.9.3->dbt-databricks==1.7.17)
  Using cached urllib3-1.26.20-py2.py3-none-any.whl.metadata (50 kB)
Collecting cachetools<6.0,>=2.0.0 (from google-auth~=2.0->databricks-sdk==0.17.0->dbt-databricks==1.7.17)
  Using cached cachetools-5.5.2-py3-none-any.whl.metadata (5.4 kB)
Collecting pyasn1-modules>=0.2.1 (from google-auth~=2.0->databricks-sdk==0.17.0->dbt-databricks==1.7.17)
  Using cached pyasn1_modules-0.4.2-py3-none-any.whl.metadata (3.5 kB)
Collecting rsa<5,>=3.1.4 (from google-auth~=2.0->databricks-sdk==0.17.0->dbt-databricks==1.7.17)
  Downloading rsa-4.9.1-py3-none-any.whl.metadata (5.6 kB)
Collecting et-xmlfile (from openpyxl<4.0.0,>=3.0.10->databricks-sql-connector<3.0.0,>=2.9.3->dbt-databricks==1.7.17)
  Using cached et_xmlfile-2.0.0-py3-none-any.whl.metadata (2.7 kB)
Collecting six>=1.5 (from python-dateutil>=2.8.2->pandas<2.2.0->dbt-databricks==1.7.17)
  Using cached six-1.17.0-py2.py3-none-any.whl.metadata (1.7 kB)
Collecting charset-normalizer<4,>=2 (from requests<3,>=2.28.1->databricks-sdk==0.17.0->dbt-databricks==1.7.17)
  Using cached charset_normalizer-3.4.1-cp312-cp312-macosx_10_13_universal2.whl.metadata (35 kB)
Collecting certifi>=2017.4.17 (from requests<3,>=2.28.1->databricks-sdk==0.17.0->dbt-databricks==1.7.17)
  Using cached certifi-2025.1.31-py3-none-any.whl.metadata (2.5 kB)
Collecting more-itertools (from jaraco.classes->keyring>=23.13.0->dbt-databricks==1.7.17)
  Using cached more_itertools-10.6.0-py3-none-any.whl.metadata (37 kB)
Collecting Babel>=2.0 (from agate~=1.7.0->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached babel-2.17.0-py3-none-any.whl.metadata (2.0 kB)
Collecting leather>=0.3.2 (from agate~=1.7.0->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached leather-0.4.0-py2.py3-none-any.whl.metadata (2.8 kB)
Collecting parsedatetime!=2.5,>=2.1 (from agate~=1.7.0->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached parsedatetime-2.6-py3-none-any.whl.metadata (4.7 kB)
Collecting python-slugify>=1.2.1 (from agate~=1.7.0->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached python_slugify-8.0.4-py2.py3-none-any.whl.metadata (8.5 kB)
Collecting pytimeparse>=1.1.5 (from agate~=1.7.0->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached pytimeparse-1.1.8-py2.py3-none-any.whl.metadata (3.4 kB)
Collecting pycparser (from cffi<2.0.0,>=1.9->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached pycparser-2.22-py3-none-any.whl.metadata (943 bytes)
Collecting importlib-metadata~=6.0 (from dbt-semantic-interfaces~=0.4.2->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached importlib_metadata-6.11.0-py3-none-any.whl.metadata (4.9 kB)
Collecting pydantic<3,>=1.10 (from dbt-semantic-interfaces~=0.4.2->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached pydantic-2.11.3-py3-none-any.whl.metadata (65 kB)
Collecting MarkupSafe>=2.0 (from Jinja2<4,>=3.1.3->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached MarkupSafe-3.0.2-cp312-cp312-macosx_11_0_arm64.whl.metadata (4.0 kB)
Collecting attrs>=22.2.0 (from jsonschema>=3.0->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached attrs-25.3.0-py3-none-any.whl.metadata (10 kB)
Collecting jsonschema-specifications>=2023.03.6 (from jsonschema>=3.0->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached jsonschema_specifications-2024.10.1-py3-none-any.whl.metadata (3.0 kB)
Collecting referencing>=0.28.4 (from jsonschema>=3.0->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached referencing-0.36.2-py3-none-any.whl.metadata (2.8 kB)
Collecting rpds-py>=0.7.1 (from jsonschema>=3.0->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached rpds_py-0.24.0-cp312-cp312-macosx_11_0_arm64.whl.metadata (4.1 kB)
Collecting msgpack>=0.5.6 (from mashumaro[msgpack]<3.15,>=3.9->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached msgpack-1.1.0-cp312-cp312-macosx_11_0_arm64.whl.metadata (8.4 kB)
Collecting pyasn1<0.7.0,>=0.6.1 (from pyasn1-modules>=0.2.1->google-auth~=2.0->databricks-sdk==0.17.0->dbt-databricks==1.7.17)
  Using cached pyasn1-0.6.1-py3-none-any.whl.metadata (8.4 kB)
Collecting zipp>=0.5 (from importlib-metadata~=6.0->dbt-semantic-interfaces~=0.4.2->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached zipp-3.21.0-py3-none-any.whl.metadata (3.7 kB)
Collecting annotated-types>=0.6.0 (from pydantic<3,>=1.10->dbt-semantic-interfaces~=0.4.2->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached annotated_types-0.7.0-py3-none-any.whl.metadata (15 kB)
Collecting pydantic-core==2.33.1 (from pydantic<3,>=1.10->dbt-semantic-interfaces~=0.4.2->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached pydantic_core-2.33.1-cp312-cp312-macosx_11_0_arm64.whl.metadata (6.8 kB)
Collecting typing-inspection>=0.4.0 (from pydantic<3,>=1.10->dbt-semantic-interfaces~=0.4.2->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached typing_inspection-0.4.0-py3-none-any.whl.metadata (2.6 kB)
Collecting text-unidecode>=1.3 (from python-slugify>=1.2.1->agate~=1.7.0->dbt-core~=1.7.0->dbt-spark~=1.7.1->dbt-databricks==1.7.17)
  Using cached text_unidecode-1.3-py2.py3-none-any.whl.metadata (2.4 kB)
Using cached dbt_databricks-1.7.17-py3-none-any.whl (68 kB)
Using cached databricks_sdk-0.17.0-py3-none-any.whl (429 kB)
Using cached databricks_sql_connector-2.9.6-py3-none-any.whl (298 kB)
Using cached dbt_spark-1.7.1-py3-none-any.whl (44 kB)
Using cached keyring-25.6.0-py3-none-any.whl (39 kB)
Using cached pandas-2.1.4-cp312-cp312-macosx_11_0_arm64.whl (10.6 MB)
Using cached protobuf-4.25.6-cp37-abi3-macosx_10_9_universal2.whl (394 kB)
Using cached alembic-1.15.2-py3-none-any.whl (231 kB)
Downloading dbt_core-1.7.19-py3-none-any.whl (1.0 MB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 1.0/1.0 MB 14.6 MB/s eta 0:00:00
Using cached google_auth-2.39.0-py2.py3-none-any.whl (212 kB)
Using cached lz4-4.4.4-cp312-cp312-macosx_11_0_arm64.whl (189 kB)
Using cached numpy-1.26.4-cp312-cp312-macosx_11_0_arm64.whl (13.7 MB)
Using cached oauthlib-3.2.2-py3-none-any.whl (151 kB)
Using cached openpyxl-3.1.5-py2.py3-none-any.whl (250 kB)
Using cached pyarrow-19.0.1-cp312-cp312-macosx_12_0_arm64.whl (30.7 MB)
Using cached python_dateutil-2.9.0.post0-py2.py3-none-any.whl (229 kB)
Using cached pytz-2025.2-py2.py3-none-any.whl (509 kB)
Using cached requests-2.32.3-py3-none-any.whl (64 kB)
Using cached SQLAlchemy-1.4.54-cp312-cp312-macosx_10_9_universal2.whl (1.6 MB)
Using cached sqlparams-6.2.0-py3-none-any.whl (17 kB)
Using cached tzdata-2025.2-py2.py3-none-any.whl (347 kB)
Using cached urllib3-1.26.20-py2.py3-none-any.whl (144 kB)
Using cached jaraco.classes-3.4.0-py3-none-any.whl (6.8 kB)
Using cached jaraco.context-6.0.1-py3-none-any.whl (6.8 kB)
Using cached jaraco.functools-4.1.0-py3-none-any.whl (10 kB)
Using cached agate-1.7.1-py2.py3-none-any.whl (97 kB)
Using cached cachetools-5.5.2-py3-none-any.whl (10 kB)
Using cached certifi-2025.1.31-py3-none-any.whl (166 kB)
Using cached cffi-1.17.1-cp312-cp312-macosx_11_0_arm64.whl (178 kB)
Using cached charset_normalizer-3.4.1-cp312-cp312-macosx_10_13_universal2.whl (196 kB)
Using cached click-8.1.8-py3-none-any.whl (98 kB)
Using cached colorama-0.4.6-py2.py3-none-any.whl (25 kB)
Using cached dbt_extractor-0.5.1-cp38-abi3-macosx_10_12_x86_64.macosx_11_0_arm64.macosx_10_12_universal2.whl (865 kB)
Using cached dbt_semantic_interfaces-0.4.4-py3-none-any.whl (118 kB)
Using cached idna-3.10-py3-none-any.whl (70 kB)
Using cached isodate-0.6.1-py2.py3-none-any.whl (41 kB)
Using cached jinja2-3.1.6-py3-none-any.whl (134 kB)
Using cached jsonschema-4.23.0-py3-none-any.whl (88 kB)
Downloading mashumaro-3.14-py3-none-any.whl (92 kB)
Using cached more_itertools-10.6.0-py3-none-any.whl (63 kB)
Using cached networkx-3.4.2-py3-none-any.whl (1.7 MB)
Using cached packaging-24.2-py3-none-any.whl (65 kB)
Using cached pathspec-0.11.2-py3-none-any.whl (29 kB)
Using cached pyasn1_modules-0.4.2-py3-none-any.whl (181 kB)
Using cached PyYAML-6.0.2-cp312-cp312-macosx_11_0_arm64.whl (173 kB)
Downloading rsa-4.9.1-py3-none-any.whl (34 kB)
Using cached six-1.17.0-py2.py3-none-any.whl (11 kB)
Downloading sqlparse-0.5.3-py3-none-any.whl (44 kB)
Using cached typing_extensions-4.13.2-py3-none-any.whl (45 kB)
Using cached et_xmlfile-2.0.0-py3-none-any.whl (18 kB)
Using cached mako-1.3.10-py3-none-any.whl (78 kB)
Using cached attrs-25.3.0-py3-none-any.whl (63 kB)
Using cached babel-2.17.0-py3-none-any.whl (10.2 MB)
Using cached importlib_metadata-6.11.0-py3-none-any.whl (23 kB)
Using cached jsonschema_specifications-2024.10.1-py3-none-any.whl (18 kB)
Using cached leather-0.4.0-py2.py3-none-any.whl (30 kB)
Using cached MarkupSafe-3.0.2-cp312-cp312-macosx_11_0_arm64.whl (12 kB)
Using cached msgpack-1.1.0-cp312-cp312-macosx_11_0_arm64.whl (82 kB)
Using cached parsedatetime-2.6-py3-none-any.whl (42 kB)
Using cached pyasn1-0.6.1-py3-none-any.whl (83 kB)
Using cached pydantic-2.11.3-py3-none-any.whl (443 kB)
Using cached pydantic_core-2.33.1-cp312-cp312-macosx_11_0_arm64.whl (1.9 MB)
Using cached python_slugify-8.0.4-py2.py3-none-any.whl (10 kB)
Using cached pytimeparse-1.1.8-py2.py3-none-any.whl (10.0 kB)
Using cached referencing-0.36.2-py3-none-any.whl (26 kB)
Using cached rpds_py-0.24.0-cp312-cp312-macosx_11_0_arm64.whl (351 kB)
Using cached pycparser-2.22-py3-none-any.whl (117 kB)
Using cached annotated_types-0.7.0-py3-none-any.whl (13 kB)
Using cached text_unidecode-1.3-py2.py3-none-any.whl (78 kB)
Using cached typing_inspection-0.4.0-py3-none-any.whl (14 kB)
Using cached zipp-3.21.0-py3-none-any.whl (9.6 kB)
Installing collected packages: text-unidecode, pytz, pytimeparse, parsedatetime, logbook, leather, zipp, urllib3, tzdata, typing-extensions, sqlparse, sqlparams, sqlalchemy, six, rpds-py, pyyaml, python-slugify, pycparser, pyasn1, pyarrow, protobuf, pathspec, packaging, oauthlib, numpy, networkx, msgpack, more-itertools, MarkupSafe, lz4, jaraco.context, idna, et-xmlfile, dbt-extractor, colorama, click, charset-normalizer, certifi, cachetools, Babel, attrs, annotated-types, typing-inspection, thrift, rsa, requests, referencing, python-dateutil, pydantic-core, pyasn1-modules, openpyxl, mashumaro, Mako, Jinja2, jaraco.functools, jaraco.classes, isodate, importlib-metadata, cffi, pydantic, pandas, minimal-snowplow-tracker, keyring, jsonschema-specifications, google-auth, alembic, agate, jsonschema, databricks-sql-connector, databricks-sdk, dbt-semantic-interfaces, dbt-core, dbt-spark, dbt-databricks
Successfully installed Babel-2.17.0 Jinja2-3.1.6 Mako-1.3.10 MarkupSafe-3.0.2 agate-1.7.1 alembic-1.15.2 annotated-types-0.7.0 attrs-25.3.0 cachetools-5.5.2 certifi-2025.1.31 cffi-1.17.1 charset-normalizer-3.4.1 click-8.1.8 colorama-0.4.6 databricks-sdk-0.17.0 databricks-sql-connector-2.9.6 dbt-core-1.7.19 dbt-databricks-1.7.17 dbt-extractor-0.5.1 dbt-semantic-interfaces-0.4.4 dbt-spark-1.7.1 et-xmlfile-2.0.0 google-auth-2.39.0 idna-3.10 importlib-metadata-6.11.0 isodate-0.6.1 jaraco.classes-3.4.0 jaraco.context-6.0.1 jaraco.functools-4.1.0 jsonschema-4.23.0 jsonschema-specifications-2024.10.1 keyring-25.6.0 leather-0.4.0 logbook-1.5.3 lz4-4.4.4 mashumaro-3.14 minimal-snowplow-tracker-0.0.2 more-itertools-10.6.0 msgpack-1.1.0 networkx-3.4.2 numpy-1.26.4 oauthlib-3.2.2 openpyxl-3.1.5 packaging-24.2 pandas-2.1.4 parsedatetime-2.6 pathspec-0.11.2 protobuf-4.25.6 pyarrow-19.0.1 pyasn1-0.6.1 pyasn1-modules-0.4.2 pycparser-2.22 pydantic-2.11.3 pydantic-core-2.33.1 python-dateutil-2.9.0.post0 python-slugify-8.0.4 pytimeparse-1.1.8 pytz-2025.2 pyyaml-6.0.2 referencing-0.36.2 requests-2.32.3 rpds-py-0.24.0 rsa-4.9.1 six-1.17.0 sqlalchemy-1.4.54 sqlparams-6.2.0 sqlparse-0.5.3 text-unidecode-1.3 thrift-0.16.0 typing-extensions-4.13.2 typing-inspection-0.4.0 tzdata-2025.2 urllib3-1.26.20 zipp-3.21.0
```

:::

dbt-databricks==1.7.17 のインストールに成功しました。

ただし以下のようにプロンプト部分の括弧が2重になってしまうのがとても気になりますね。

> ```bash
> $ source my-venv-3.12.10/bin/activate
> ((my-venv-3.12.10) )
> $ pip install dbt-databricks==1.7.17
> ```

対応する Issue はこちらなのですが Python 3.12 ではもうバグ修正をしないようなのでこの2重括弧と共に生きていくしかないです。
メンテナーの方も仰っていますが目立つバグなのでどうしても気になってしまいます。

@[card](https://github.com/python/cpython/issues/132361)

## 5. まとめ

ライブラリのバージョンを固定した後色々と帳尻合わせしようとすると大変なことが起きがちですね。
