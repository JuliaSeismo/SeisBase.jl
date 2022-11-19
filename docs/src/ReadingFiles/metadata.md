# Metadata Files

```@docs
read_meta!
read_meta
```

## Supported File Formats

| File Format               | String    |
| ------------------------- | --------- | 
| Dataless SEED             | dataless  |   
| FDSN Station XML          | sxml      |
| SACPZ                     | sacpz     |
| SEED RESP                 | resp      |

**Warning**: Dataless SEED, SACPZ, and RESP files must be Unix text files; DOS
text files, whose lines end in "\\r\\n", will not read properly. Convert with
`dos2unix` or equivalent Windows Powershell commands.

## Supported Keywords
| KW    | Used By  | Type      | Default   | Meaning                        |
| ----- | -------- | --------- | --------- | ------------------------------ |
| memmap| all      | Bool      | false     | use Mmap.mmap to buffer file?  |        
| msr   | sxml     | Bool      | false     | read full MultiStageResp?      |
| s     | all      | TimeSpec  |           | Start time                     |
| t     | all      | TimeSpec  |           | Termination (end) time         |
| units | resp     | Bool      | false     | fill in MultiStageResp  units? |
|       | dataless |           |           |                                |
| v     | all      | Integer   | 0         | verbosity                      |

**Note**: `mmap=true` improves read speed for ASCII formats but requires caution. Julia language handling of SIGBUS/SIGSEGV and associated risks is unknown and undocumented.
