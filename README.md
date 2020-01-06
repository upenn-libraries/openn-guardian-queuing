# Guardian queuing

# Scripts here

TODO:

- `build_inventory.rb`
- `guardian_jobs.rb`
- `guardian_ps.rb`
- `guardian_statuses.rb`
- `guardian_uptime.rb`
- `order_walters_archives.rb`
- `prep_size_csv.rb`
- `rename_todos.rb`
- `sort_todo_files.rb`
- `split_by_size.rb`

# Pushing/Resetting todos on guardian servers

Create new todos:

Add new folders to Guardian Priorities workbook (stored eslewhere)

### Build inventory yaml

Run `build_inventory.rb` against Guardian Sizes CSV from Guardian Priorities
spreadsheet to create yml files for each repository. CSV should only contain new/changed items. CSV should shoud look
like:


```csv
Key,repo,Path extension,Priority,Group,Repo Name,size,size_gb,folder,In Glacier,Size in Glacier,STATUS,Notes
0002_mscoll990_item16,0002,,1,A,University of Pennsylvania Libraries,2083845,1.99,mscoll990_item16,,,,
0002_mscodex21_v1,0002,,1,B,University of Pennsylvania Libraries,33592322,32.04,mscodex21_v1,,,,
0002_mscodex45_v1,0002,,1,C,University of Pennsylvania Libraries,34721541,33.11,mscodex45_v1,,,,
0002_mscodex45_v2,0002,,1,D,University of Pennsylvania Libraries,39216233,37.4,mscodex45_v2,,,,
0002_mscodex21_v2,0002,,1,E,University of Pennsylvania Libraries,28170680,26.87,mscodex21_v2,,,,
```

```
ruby scripts/build_inventory.rb data/2019-12-batches.csv
```

Output files will be something like:

```
inventory_0001.yml
inventory_0002.yml
inventory_0003.yml
...

```

### Generate CSV using `guardian_manifest.rb`


```
for x in ~/code/GIT/openn-guardian-queuing/tmp/*.yml; do 
  bundle exec ruby guardian_manifest.rb $x $x.csv
done
```

Move CSV's to some location

```
mv inventory_000*.yml.csv ~/code/GIT/openn-guardian-queuing/tmp/
```

Result:

```
inventory_0001.yml
inventory_0001.yml.csv
inventory_0002.yml
inventory_0002.yml.csv
inventory_0003.yml
inventory_0003.yml.csv
...

```

### Generate todo files using `csv_to_yml.rb`

<https://github.com/upenn-libraries/csv_to_yml>

From the  `csv_to_yml.rb` directory:

```
for x in ../../../GIT/openn-guardian-queuing/tmp/*.csv; do
  bundle exec ruby csv_to_yml.rb ${x} todo ../../../GIT/openn-guardian-queuing/tmp/
done
```

Result will be:

```
0002_msbox23_folder26.todo
0002_mscodex21_v1.todo
0002_mscodex21_v2.todo
0002_mscodex21_v3.todo
0002_mscodex21_v4.todo
0002_mscodex26_v1.todo
0002_mscodex26_v2.todo
0002_mscodex27_v1.todo
0002_mscodex27_v2.todo
0002_mscodex27_v3.todo
0002_mscodex27_v4.todo
0002_mscodex45_v1.todo
0002_mscodex45_v2.todo
0002_mscodex_39.todo
0002_mscoll990_item16.todo
0003_BMC_MS02.todo
```

### Group todo files using `sort_todo_files.rb`

```
ruby scripts/sort_todo_files.rb tmp/batch-2019-Dec.csv tmp
```

`tmp` is the directory contain the the todo files and `tmp/batch-2019-Dec.csv`
is a csv worksheet Glacier Sizes from the Glacier Priorities workbook.

Each todo file will be copy to the `tmp/todo` and its name prepended with an group tag and serial number:

```
cp tmp/0002_mscoll990_item16.todo /Users/emeryr/code/GIT/openn-guardian-queuing/tmp/todo/A00001_0002_mscoll990_item16.todo
cp tmp/0002_mscodex21_v1.todo /Users/emeryr/code/GIT/openn-guardian-queuing/tmp/todo/B00001_0002_mscodex21_v1.todo
cp tmp/0002_mscodex45_v1.todo /Users/emeryr/code/GIT/openn-guardian-queuing/tmp/todo/C00001_0002_mscodex45_v1.todo
cp tmp/0002_mscodex45_v2.todo /Users/emeryr/code/GIT/openn-guardian-queuing/tmp/todo/D00001_0002_mscodex45_v2.todo
cp tmp/0002_mscodex21_v2.todo /Users/emeryr/code/GIT/openn-guardian-queuing/tmp/todo/E00001_0002_mscodex21_v2.todo
cp tmp/0002_mscodex21_v4.todo /Users/emeryr/code/GIT/openn-guardian-queuing/tmp/todo/F00001_0002_mscodex21_v4.todo
cp tmp/0002_mscodex21_v3.todo /Users/emeryr/code/GIT/openn-guardian-queuing/tmp/todo/G00001_0002_mscodex21_v3.todo
cp tmp/0002_mscodex27_v1.todo /Users/emeryr/code/GIT/openn-guardian-queuing/tmp/todo/A00002_0002_mscodex27_v1.todo
cp tmp/0002_mscodex27_v3.todo /Users/emeryr/code/GIT/openn-guardian-queuing/tmp/todo/B00002_0002_mscodex27_v3.todo
cp tmp/0002_mscodex26_v1.todo /Users/emeryr/code/GIT/openn-guardian-queuing/tmp/todo/C00002_0002_mscodex26_v1.todo
cp tmp/0002_mscodex26_v2.todo /Users/emeryr/code/GIT/openn-guardian-queuing/tmp/todo/D00002_0002_mscodex26_v2.todo
cp tmp/0002_mscodex27_v4.todo /Users/emeryr/code/GIT/openn-guardian-queuing/tmp/todo/E00002_0002_mscodex27_v4.todo
cp tmp/0002_mscodex27_v2.todo /Users/emeryr/code/GIT/openn-guardian-queuing/tmp/todo/F00002_0002_mscodex27_v2.todo
```

### Tar and copy files to guardian servers

```
cd tmp
mv todo todo-batch3-20191217
tar czf todo-batch3-20191217.tgz todo-batch3-20191217/**
for x in g0{1,2,3,4}; do ssh $x "sudo cp /home/LIBRARY/emeryr/todo-batch3-20191217.tgz /root:"; done
```

### On each guardian server

Become root
Copy tgz to /root
Untar

```
guardian02[~]$ root
root@guardian02[~]# ls ~emeryr
openn_guardian_todos.tgz  todo-batch3-20191217.tgz
root@guardian02[~]# cp ~emeryr/todo-batch3-20191217.tgz .
root@guardian02[~]# tar xf todo-batch3-20191217.tgz

```

Copy files to `guardian_guardian_todos` docker volume

```
root@guardian02[~]# docker volume ls
DRIVER              VOLUME NAME
local               guardian_guardian
local               guardian_guardian_todos
local               guardian_openn_site_data
local               guardian_openn_walters_data
root@guardian02[~]# docker volume inspect guardian_guardian_todos
[
    {
        "CreatedAt": "2019-12-09T16:13:17-05:00",
        "Driver": "local",
        "Labels": {
            "com.docker.stack.namespace": "guardian"
        },
        "Mountpoint": "/var/lib/docker/volumes/guardian_guardian_todos/_data",
        "Name": "guardian_guardian_todos",
        "Options": null,
        "Scope": "local"
    }
]
root@guardian02[~]# cp todo-batch3-20191217/B000* todo-batch3-20191217/C000* /var/lib/docker/volumes/guardian_guardian_todos/_data/
```

Clean up `/work`. As root:

```bash
cd /work/
tar czf openn-logs.tgz openn-*.log
# use cp -i flag so we don't overwrite by mistake
cp -i openn-logs.tgz /root
# get the names of all files, excluding the logs
dirs=$(ls | grep -v \.log)
rm -rf $dirs
```

In the todos directory:

```
cd /var/lib/docker/volumes/guardian_guardian_todos/_data
```

Rename `*-processing` files:

```
# first test by echoing the command
for x in *.*-processing; do new=$(sed 's/\.[0-9][0-9]*-processing//' <<< $x).todo; echo mv -v $x $new; done
# then remove echo and run the command
for x in *.*-processing; do new=$(sed 's/\.[0-9][0-9]*-processing//' <<< $x).todo; mv -v $x $new; done
```

Rename the `*.FAIL files:

```bash
root@guardian02[/var/lib..odos/_data]# ls *.FAIL
B00522_0002_ms_coll_700_item106.FAIL  C00532_0016_2003_82_443.FAIL   C00569_0016_29_201_709.FAIL  C00591_0007_lehigh_002.FAIL  C00621_0007_BookofHoursoftheRomanuse_18.FAIL
...

root@guardian02[/var/lib..odos/_data]# for x in *.FAIL; do new=$(basename $x .FAIL).todo; echo mv -v $x $new; done
mv -v B00522_0002_ms_coll_700_item106.FAIL B00522_0002_ms_coll_700_item106.todo
mv -v B00636_0002_ms_coll_700_item187.FAIL B00636_0002_ms_coll_700_item187.todo
...

root@guardian02[/var/lib..odos/_data]# for x in *.FAIL; do new=$(basename $x .FAIL).todo; mv -v $x $new; done
‘B00522_0002_ms_coll_700_item106.FAIL’ -> ‘B00522_0002_ms_coll_700_item106.todo’
‘B00636_0002_ms_coll_700_item187.FAIL’ -> ‘B00636_0002_ms_coll_700_item187.todo’
```

Rename any `\*-running` files:

```
root@guardian02[/var/lib..odos/_data]# mv B00522_0002_ms_coll_700_item106.glacier-running B00522_0002_ms_coll_700_item106.todo
```

Start the processes:

```
docker exec -d fcc9aa82c4a4 \
  sh -c "cd /usr/src/app; \
  bundle exec ruby guardian-glacier-transfer /todos/A0*.todo \
  >> /zip_workspace/openn-A-`date +%Y%m%dT%H%M%S-%Z`.log 2>&1"
```
