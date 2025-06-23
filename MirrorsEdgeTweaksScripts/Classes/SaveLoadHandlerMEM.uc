/**
 *  Class for providing persistent saving and loading of variables and player states (e.g. SaveLocation and TpToSavedLocation functions in MirrorsEdgeCheatManager class)
 *
 *  The MirrorsEdgeCheatManager class is not persistent and will be reset upon level changes / level restarts, resulting in the saved properties
 *  of the SaveLocation function being lost, which can be annoying.
 *
 *  This class makes use of the Config specifier which is supposed to write values to TdEngine.ini and TdInput.ini, but turns out we can also abuse writing to
 *  non-existent configs which makes the saved values fallback to being written in memory. This allows the saved properties to persist beyond
 *  just the current level, making it perform more in line with mmultiplayer's save/load trainer.
 */

class SaveLoadHandlerMEM extends Object
    config(Game);

struct SaveDataCell
{
    var string Name;          // Name of the data
    var string SerialisedValue; // Serialised string value of the data
};

var globalconfig array<SaveDataCell> SaveDataCells;

// Save data by name with a serialised string value
function SaveData(string SaveName, string SerialisedValue)
{
    local int i;
    local SaveDataCell Cell;
    local bool CellFound;

    foreach SaveDataCells(Cell, i)
    {
        if (Cell.Name == SaveName)
        {
            CellFound = true;
            SaveDataCells[i].SerialisedValue = SerialisedValue;
            SaveConfig();
            return;
        }
    }

    if (!CellFound)
    {
        Cell.Name = SaveName;
        Cell.SerialisedValue = SerialisedValue;
        SaveDataCells.AddItem(Cell); // Correct array assignment
        SaveConfig();
    }
}

// Load data by name and return the serialised string
function string LoadData(string SaveName)
{
    local int i;
    local SaveDataCell Cell;

    foreach SaveDataCells(Cell, i)
    {
        if (Cell.Name == SaveName)
        {
            return SaveDataCells[i].SerialisedValue;
        }
    }

    return ""; // Return empty if not found
}

// Utility function to serialise a vector
static function string SerialiseVector(vector V)
{
    return V.X $ "," $ V.Y $ "," $ V.Z;
}

static function string SerialiseRotator(rotator R)
{
    return R.Pitch $ "," $ R.Yaw $ "," $ R.Roll;
}

// Utility function to deserialise a vector
static function vector DeserialiseVector(string Serialised)
{
    local vector V;
    local string Temp;
    local int CommaIndex;

    if (Serialised == "")
    {
        return vect(0, 0, 0); // Default vector if no data
    }

    CommaIndex = InStr(Serialised, ",");
    if (CommaIndex != -1)
    {
        Temp = Left(Serialised, CommaIndex);
        V.X = float(Temp);

        Serialised = Mid(Serialised, CommaIndex + 1);
        CommaIndex = InStr(Serialised, ",");
        if (CommaIndex != -1)
        {
            Temp = Left(Serialised, CommaIndex);
            V.Y = float(Temp);

            Serialised = Mid(Serialised, CommaIndex + 1);
            V.Z = float(Serialised);
        }
    }
    return V;
}

// Utility function to serialise a rotator
static function rotator DeserialiseRotator(string Serialised)
{
    local rotator R;
    local string Temp;
    local int CommaIndex;

    if (Serialised == "")
    {
        return rot(0, 0, 0); // Default rotator if no data
    }

    CommaIndex = InStr(Serialised, ",");
    if (CommaIndex != -1)
    {
        Temp = Left(Serialised, CommaIndex);
        R.Pitch = int(Temp);

        Serialised = Mid(Serialised, CommaIndex + 1);
        CommaIndex = InStr(Serialised, ",");
        if (CommaIndex != -1)
        {
            Temp = Left(Serialised, CommaIndex);
            R.Yaw = int(Temp);

            Serialised = Mid(Serialised, CommaIndex + 1);
            R.Roll = int(Serialised);
        }
    }
    return R;
}

defaultproperties
{
}
