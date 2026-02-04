namespace ManejoPresupuestos.Models
{
    public class SimpleOption
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = "";
    }

    public class ReporteCotizacionesTotales
    {
        public int Cotizaciones { get; set; }
        public decimal? MontoTotal { get; set; }

        public int Aceptadas { get; set; }
        public int Pendientes { get; set; }
        public int Rechazadas { get; set; }

        public int Convertidas { get; set; }
        public decimal? ConversionPct { get; set; }
        public decimal? AvgDiasAConversion { get; set; }
    }

    public class ReporteCotizacionEstatusResumenRow
    {
        public int CotizacionEstatusId { get; set; }
        public string CotizacionEstatusNombre { get; set; } = "";
        public int Cotizaciones { get; set; }
        public decimal? Monto { get; set; }
        public int Convertidas { get; set; }
        public decimal? ConversionPct { get; set; }
    }

    public class ReporteCotizacionSeguimientoRow
    {
        public int CotizacionId { get; set; }
        public int PedidoId { get; set; }
        public int ClienteId { get; set; }
        public string? ClienteNombre { get; set; }

        public int CotizacionEstatusId { get; set; }
        public string? CotizacionEstatusNombre { get; set; }
        public string? Categoria { get; set; } // Aceptada|Pendiente|Rechazada

        public DateTime CotizacionFechaCreacion { get; set; }
        public DateTime? FechaVigencia { get; set; }

        public decimal MontoCotizacion { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal Saldo { get; set; }

        public bool Convertida { get; set; }
        public DateTime? FechaConversion { get; set; }
        public int? DiasAConversion { get; set; }

        public DateTime? UltimoPagoFecha { get; set; }
        public string? UltimoPagoMetodo { get; set; }
        public string? UltimoPagoReferencia { get; set; }
        public string? UltimoPagoTipoNombre { get; set; }
    }

    public class ReporteCotizacionesSeguimientoViewModel
    {
        // filtros
        public DateTime Desde { get; set; }
        public DateTime Hasta { get; set; }
        public int? ClienteId { get; set; }
        public int? CotizacionEstatusId { get; set; }
        public bool SoloConvertidas { get; set; }
        public bool SoloUltimaPorPedido { get; set; }
        public decimal? MinMonto { get; set; }
        public string? Q { get; set; }

        // data
        public ReporteCotizacionesTotales Totales { get; set; } = new();
        public List<ReporteCotizacionEstatusResumenRow> PorEstatus { get; set; } = new();
        public List<ReporteCotizacionSeguimientoRow> Rows { get; set; } = new();

        // dropdowns
        public List<SimpleOption> Clientes { get; set; } = new();
        public List<SimpleOption> Estatus { get; set; } = new();
    }
}