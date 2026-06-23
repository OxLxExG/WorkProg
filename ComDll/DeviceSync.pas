unit DeviceSync;

interface

uses
  System.SysUtils, System.DateUtils, Winapi.Windows, tools, DeviceIntf;


// Основная процедура однократной высокоточной синхронизации
procedure SyncDeviceTimeHighPrecision(DelayTime: TDateTime; ResultEvent: TSetDelayEvent);

implementation


procedure SyncDeviceTimeHighPrecision(DelayTime: TDateTime; ResultEvent: TSetDelayEvent);
var
  TimePC: TDateTime;
  ElapsedFrames: Double;
  NextFrameIndex: UInt32;
  TargetFrameTime: TDateTime;
  CodedDate: UInt32;
  CodedDelay: Int32;

  // Переменные таймингов
  TotalTransitTimeSec: Double;
  TimeToWaitMS: Integer;

  // Бинарный буфер пакета
  TxBuffer: array[0..10] of Byte;
  Crc: Word;
begin
  TimePC := Now;

  // 1. Рассчитываем сетку кадров ПК
  ElapsedFrames := (TimePC - DateEpoch) / FrameInDays;
  NextFrameIndex := Trunc(ElapsedFrames) + 1;
  TargetFrameTime := DateEpoch + (NextFrameIndex * FrameInDays);

  // 2. Упреждение: 1.16 мс (пакет по UART + 3.5 тишины) + 14 мс (компенсация буфера ОС USB-UART)
  TotalTransitTimeSec := 0.01516;

  // 3. Защита: если до кадра осталось меньше 40 мс, переносим на следующий кадр,
  // иначе Windows гарантированно не успеет проснуться от Sleep
  if ((TargetFrameTime - TimePC) * SecInDay) < (TotalTransitTimeSec + 0.040) then
  begin
    Inc(NextFrameIndex);
    TargetFrameTime := DateEpoch + (NextFrameIndex * FrameInDays);
  end;

  // 4. Расчет полезной нагрузки строго для выбранного будущего кадра
  CodedDate := NextFrameIndex;
  CodedDelay := Round((TargetFrameTime - DelayTime) / FrameInDays);

  // 5. Заранее (ДО начала ожидания!) упаковываем буфер и считаем CRC16.
  // Это убирает программные задержки в критический момент отправки.
  TxBuffer[0] := $AA; // Пример байта преамбулы
  Move(CodedDate, TxBuffer[1], 4);  // 4 байта Date
  Move(CodedDelay, TxBuffer[5], 4); // 4 байта Delay


  // 6. Считаем время ожидания в миллисекундах
  TimeToWaitMS := Round(((TargetFrameTime - Now) * SecInDay - TotalTransitTimeSec) * 1000);

  // 7. Основной сон. Вычитаем 2 мс зазора, чтобы планировщик Windows не "переспал" точку старта
  if TimeToWaitMS > 5 then
    Sleep(TimeToWaitMS - 2);

  // 8. Финальный микро-доводчик (Spin-wait). Занимает не более 2-3 мс, CPU не нагрузит.
  while ((TargetFrameTime - Now) * SecInDay) > TotalTransitTimeSec do
  begin
    // Ловим точную приборную отметку (TargetFrameTime - 15.16 мс)
  end;

  // 9. Мгновенная отправка уже готового буфера в физический порт
  //HardwareUartSend(TxBuffer, 11);
end;

end.

