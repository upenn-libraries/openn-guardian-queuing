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

# Adding new repositories to the list

On the OPenn server, run `openn_sizes.rb` to get the CSV of new items to add to
the Guardian Sizes sheet of the Guardian Priorities.xlsx file.

Before you run the script save the current Guardian Size sheet from the
Guardian Priorities.xlsx workbook as

- `data/Glacier_Priorities-Glacier_sizes.csv`

Also save as a CSV the current 'Completed' sheet, as

- `data/Glacier_Priorities-Completed.csv`

Set the `OPENN_ROOT_DIR` environment variable. This is the local directory that
serves as the OPenn site root directory. Its contents look like this:

```
-rw-rw-r--  1 emeryr domain users 7.3K Apr 14 19:10 CuratedCollections.html
drwxrwxr-x 52 emeryr openn         109 Apr 10 11:23 Data
drwxrwxr-x  6 emeryr openn          95 Apr 10 11:22 html
-rw-rw-r--  1 emeryr domain users  13K Apr 14 19:10 ReadMe.html
-rw-rw-r--  1 emeryr domain users  44K Apr 14 19:10 Repositories.html
-rw-r--r--  1 emeryr openn          24 Sep 10  2015 robots.txt
-rw-r--r--  1 emeryr openn        4.3K May 18  2018 Search.html
-rw-rw-r--  1 emeryr domain users  88K Apr 14 19:10 TechnicalReadMe.html
```

Run the script:

```
OPENN_ROOT_DIR=/path/to/OPenn ruby scripts/openn_sizes.rb > `sizes.csv`
```

Now add the new objects to the Glacier Sizes worksheet:

- Copy `sizes.csv` to your local computer.

- Create a new empty Excel workbook.

- Import `sizes.csv` into the new workbook as CSV, _set all columns to Text_.

- Copy all rows _except for the header_.

- Using Paste Special... > Values, paste the new rows to the end of the
  Guardian Priorities/Guardian Sizes sheet.

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

Move CSVs to some location

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

Each todo file will be copied to `tmp/todo` and its name prepended with a group tag and serial number:

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

Move all todo files to `/root/todo`

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
tar czf openn-`date +%Y%m%d`-logs.tgz openn-*.log
# use cp -i flag so we don't overwrite by mistake
cp -i openn-logs.tgz /root
# get the names of all files, excluding the logs
dirs=$(ls | grep -v \.log)
rm -rf $dirs
```

Replace all the `.FAIL`, `.*-processing`, and `.*-running` files with the originals.

**DO NOT RENAME FILES TO x.todo**


```
for x in *.FAIL; do source=/root/todo/`basename $x .FAIL`.todo; cp -v $source .; mv -v $x $x.bak; done
```

Repeat for `.*-processing` and `.*-running` files.

Start the processes:

```
docker exec -d fcc9aa82c4a4 \
  sh -c "cd /usr/src/app; \
  bundle exec ruby guardian-glacier-transfer /todos/A0*.todo \
  >> /zip_workspace/openn-A-`date +%Y%m%dT%H%M%S-%Z`.log 2>&1"
```
