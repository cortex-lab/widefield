
function pathOut = pathForThisOS(pathIn)

pathOut = pathIn;
pathOut(pathOut=='/') = filesep;
pathOut(pathOut=='\') = filesep;