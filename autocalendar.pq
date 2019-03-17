let
    Source = (StartDate as date, EndDate as date, optional Culture as nullable text) as table =>

    let
        DayCount = Duration.Days(Duration.From(EndDate - StartDate)),
        Source = List.Dates(StartDate,DayCount,#duration(1,0,0,0)),

        // I added the optional metadata header for the third argument - type table [Date = date] removing some unneccasary M
        TableFromList = Table.FromList(Source, Splitter.SplitByNothing(), type table [Date = date]),

        /*  I'm always curious in terms of memory management because PQ supports Int8.Type, Int16.Type, Int32.Type and Int64.Type 
            but as you force them into the optional argument in the function's or steps which allow a type to be passed it seems to misrepresent them
            at least graphically - for instance the [Quarter] below is set as Int8.Type and the header icon should be "1 2 3" denoting whole numbers
            though the icon shows 1.2 denoting a decimal number. Also I'm almost 200% positive that once it's actually loaded into the Vertipaq Engine
            all values are stored as 64 Bit - it just comes across as extremely wasteful IMHO.
        */

        InsertYear = Table.AddColumn(TableFromList, "Year", each Date.Year([Date]), Int64.Type),
        InsertQuarter = Table.AddColumn(InsertYear, "Quarter", each Date.QuarterOfYear([Date]), Int8.Type),
        InsertMonth = Table.AddColumn(InsertQuarter, "MonthNr", each Date.Month([Date]), Int8.Type),
        InsertYearMonth = Table.AddColumn(InsertMonth, "YearMonth", each Date.ToText([Date],"yyyyMM"), type text),
        InsertDay = Table.AddColumn(InsertYearMonth, "Day", each Date.Day([Date]), Int8.Type),
        InsertDayInt = Table.AddColumn(InsertDay, "DateInt", each [Year] * 10000 + [MonthNr] * 100 + [Day], Int64.Type),
        InsertMonthName = Table.AddColumn(InsertDayInt, "Month", each Date.ToText([Date], "MMMM", Culture), type text),
        InsertMonthNameShort = Table.AddColumn(InsertMonthName, "Month short", each Date.ToText([Date], "MMM", Culture), type text),
        InsertDayWeek = Table.AddColumn(InsertMonthNameShort, "DayInWeek", each Date.DayOfWeek([Date],Day.Monday)+1, Int8.Type),
        InsertDayName = Table.AddColumn(InsertDayWeek, "DayOfWeekName", each Date.ToText([Date], "dddd", Culture), type text),
        InsertYearWeek = Table.AddColumn(InsertDayName, "YearWeek", each  Text.From([Year]) & Text.PadStart(Text.From(Date.WeekOfYear([Date])),2,"0"), type text),
        InsertWeekStarting = Table.AddColumn(InsertYearWeek, "WeekStart", each Date.StartOfWeek([Date]), type date),
        InsertWeekEnding = Table.AddColumn(InsertWeekStarting, "WeekEnding", each Date.EndOfWeek([Date]), type date)
    in
        InsertWeekEnding,

    #"Invoked FunctionSource" = Source(#date(1991, 1, 1), #date(2018, 01, 01), "en-us"),
    #"Inserted: WeekofYear" = Table.AddColumn(#"Invoked FunctionSource", "WeekofYear", each Date.WeekOfYear([Date]), Int64.Type),
    #"Custom: Sorting Order YYYYMM" = Table.AddColumn(#"Inserted: WeekofYear", "Sorting Order", each [Year]*100 + [MonthNr], Int64.Type),
    #"Removed Other Columns" = Table.SelectColumns(#"Custom: Sorting Order YYYYMM",{"Date", "Year", "MonthNr", "YearMonth", "Day", "Month", "Month short", "DayInWeek", "DayOfWeekName", "WeekStart", "WeekEnding", "WeekofYear"})
in
    #"Removed Other Columns"
