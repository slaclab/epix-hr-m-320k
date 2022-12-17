      -- Digital board env monitor
      adcMonSpiClk          => adcMonSpiClk,
      adcSpiData            => adcSpiData,
      adcMonClkP            => adcMonClkP,
      adcMonClkM            => adcMonClkM,
      adcMonPdwn            => adcMonPdwn,
      adcMonSpiCsb          => adcMonSpiCsb,
      slowAdcDout           => slowAdcDout,
      slowAdcDrdyL          => slowAdcDrdyL,
      slowAdcSyncL          => slowAdcSyncL,
      slowAdcSclk           => slowAdcSclk,
      slowAdcCsb            => slowAdcCsb,
      slowAdcDin            => slowAdcDin,
      slowAdcRefClk         => slowAdcRefClk,

      -- Power and communication env Monitor
      pcbAdcDrdyL           => pcbAdcDrdyL,
      pcbAdcDout            => pcbAdcDout,
      pcbAdcCsb             => pcbAdcCsb,
      pcbAdcSclk            => pcbAdcSclk,
      pcbAdcDin             => pcbAdcDin,
      pcbAdcSyncL           => pcbAdcSyncL,
      pcbAdcRefClk          => pcbAdcRefClk,

      -- Serial number
      serialNumber          => serialNumber

            -- Power
      syncDcdc              => syncDcdc,
      ldoShtdnL             => ldoShtdnL,
      dcdcSync              => dcdcSync,
      pcbSync               => pcbSync,
      pcbLocalSupplyGood    => pcbLocalSupplyGood