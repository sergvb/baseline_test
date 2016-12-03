clc, clear all;

filter = [ubx.Message.RXM_RAWX, ubx.Message.NAV_POSECEF];

dataA = readData('..\data\RS_matv_50mm_01.bin', filter);
dataB = readData('..\data\RS_matv_50mm_02.bin', filter);

groupA = groupPackets(dataA);
groupB = groupPackets(dataB);

X = computeDifferences(groupA, groupB);