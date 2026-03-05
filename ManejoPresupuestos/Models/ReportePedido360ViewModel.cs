namespace ManejoPresupuestos.Models
{
    public class ReportePedido360Header
    {
        public int PedidoId { get; set; }
        public int UsuarioId { get; set; }

        public int ClienteId { get; set; }
        public string? ClienteNombre { get; set; }
        public string? Telefono { get; set; }
        public string? WhatsApp { get; set; }
        public string? Instagram { get; set; }
        public string? Email { get; set; }
        public string? Direccion { get; set; }
        public bool ClienteEstaActivo { get; set; }
        public bool ClienteEsEmpresa { get; set; }

        public int PedidoEstatusId { get; set; }
        public string? PedidoEstatusNombre { get; set; }

        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaEntregaEstimada { get; set; }
        public string? Notas { get; set; }

        public decimal? TotalEstimado { get; set; }

        // OJO: el SP regresa CotizacionIdVinculada, no CotizacionId
        public int? CotizacionIdVinculada { get; set; }

        public decimal? CotizacionTotal { get; set; }
        public decimal? TotalPagado { get; set; }
        public decimal? TotalPendiente { get; set; }

        public int PedidoItemsActivos { get; set; }
        public int ProduccionItemsActivos { get; set; }

        public bool PedidoEstaActivo { get; set; }

        // Helpers opcionales (por compat / comodidad)
        public int? CotizacionId => CotizacionIdVinculada;
        public bool EstaActivo => PedidoEstaActivo;
    }

    public class ReportePedido360ItemRow
    {
        public int PedidoItemId { get; set; }
        public int PedidoId { get; set; }

        public int ProductoId { get; set; }
        public string? ProductoNombre { get; set; }
        public int ProductoCategoriaId { get; set; }
        public string? ProductoCategoriaNombre { get; set; }

        public int Cantidad { get; set; }
        public decimal? PrecioUnitarioEstimado { get; set; }
        public string? Notas { get; set; }
        public bool EstaActivo { get; set; }

        // extras del SP (outer apply)
        public int ProduccionItems { get; set; }
        public int CantidadEnProduccion { get; set; }
        public decimal PesoEstimadoGrTotal { get; set; }
        public decimal PesoRealGrTotal { get; set; }
    }

    public class ReportePedido360CotizacionRow
    {
        public string RowType { get; set; } = "ITEM"; // HEADER|ITEM

        // Header
        public int CotizacionId { get; set; }
        public int PedidoId { get; set; }
        public int CotizacionEstatusId { get; set; }
        public string? CotizacionEstatusNombre { get; set; }
        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaVigencia { get; set; }
        public string? Notas { get; set; }
        public bool EstaActivo { get; set; }
        public decimal? CotizacionTotal { get; set; }

        // Item
        public int? CotizacionItemId { get; set; }
        public int? ConceptoTipoId { get; set; }
        public string? ConceptoTipoNombre { get; set; }

        public int? ProductoId { get; set; }
        public string? ProductoNombre { get; set; }
        public int? ProductoCategoriaId { get; set; }
        public string? ProductoCategoriaNombre { get; set; }

        public string? Concepto { get; set; }
        public decimal? Cantidad { get; set; }
        public decimal? PrecioUnitario { get; set; }
        public decimal? Subtotal { get; set; }
        public string? ItemNotas { get; set; }
    }

    public class ReportePedido360PagoRow
    {
        public int PagoId { get; set; }
        public int CotizacionId { get; set; }
        public int PagoTipoId { get; set; }
        public string? PagoTipoNombre { get; set; }

        public decimal Monto { get; set; }
        public DateTime FechaPago { get; set; }

        public string? Metodo { get; set; }
        public string? Referencia { get; set; }
        public string? Notas { get; set; }

        public DateTime FechaCreacion { get; set; }
        public bool EstaActivo { get; set; }
    }

    public class ReportePedido360ProduccionRow
    {
        public int ProduccionItemId { get; set; }
        public int PedidoId { get; set; }
        public int PedidoItemId { get; set; }

        public int UsuarioId { get; set; }

        public int ProductoId { get; set; }
        public string? ProductoNombre { get; set; }
        public int ProductoCategoriaId { get; set; }
        public string? ProductoCategoriaNombre { get; set; }

        public int Cantidad { get; set; }

        public int ProduccionEstatusId { get; set; }
        public string? ProduccionEstatusNombre { get; set; }
        public int ProduccionEstatusOrden { get; set; }
        public string? BadgeClass { get; set; }

        public int? ImpresoraId { get; set; }
        public string? ImpresoraNombre { get; set; }
        public string? ImpresoraModelo { get; set; }

        public int? RecetaId { get; set; }
        public string? RecetaNombre { get; set; }
        public string? TiempoImpresion { get; set; }
        public int? TiempoImpresionMin { get; set; }
        public int? TiempoPostMin { get; set; }

        public decimal? PesoEstimadoGr { get; set; }
        public decimal? PesoRealGr { get; set; }

        public DateTime? FechaInicio { get; set; }
        public DateTime? FechaFin { get; set; }

        public bool InventarioAplicado { get; set; }
        public string? Notas { get; set; }
        public string? NotasOperativas { get; set; }

        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaActualizacion { get; set; }
        public bool EstaActivo { get; set; }
    }

    public class ReportePedido360ConsumoRow
    {
        public int ProduccionInventarioConsumoId { get; set; }
        public int ProduccionItemId { get; set; }

        public int PedidoId { get; set; }
        public int? PedidoItemId { get; set; }
        public int? ProductoId { get; set; }
        public int? CantidadItem { get; set; }

        public int? RecetaId { get; set; }
        public string? RecetaNombre { get; set; }

        public int InventarioId { get; set; }
        public string? InsumoNombre { get; set; }

        //  FIX: el SP trae CantidadConsumida, no Cantidad
        public decimal CantidadConsumida { get; set; }

        // extras del SP (planeación)
        public decimal? CantidadPlaneadaBase { get; set; }
        public decimal? CantidadPlaneadaTotal { get; set; }

        public string? UnidadNombre { get; set; }

        public decimal? DisponibleAntes { get; set; }
        public decimal? DisponibleDespues { get; set; }

        public int? DesdeEstatusId { get; set; }
        public int? HaciaEstatusId { get; set; }

        public string? Notas { get; set; }
        public int UsuarioId { get; set; }
        public DateTime Fecha { get; set; }

        // compat para que si en algún lado usas Cantidad, ya no salga 0
        public decimal Cantidad => CantidadConsumida;
    }

    public class ReportePedido360HistoriaRow
    {
        public string Tipo { get; set; } = "PEDIDO"; // PEDIDO|PRODUCCION
        public int BitacoraId { get; set; }

        public int PedidoId { get; set; }
        public int? ProduccionItemId { get; set; }
        public int? PedidoItemId { get; set; }

        public int UsuarioId { get; set; }

        public int DesdeEstatusId { get; set; }
        public string? DesdeEstatusNombre { get; set; }
        public int HaciaEstatusId { get; set; }
        public string? HaciaEstatusNombre { get; set; }

        public string? Notas { get; set; }
        public DateTime Fecha { get; set; }
    }

    public class ReportePedido360ViewModel
    {
        public int PedidoId { get; set; }
        public string? Mensaje { get; set; }

        public ReportePedido360Header? Header { get; set; }

        public List<ReportePedido360ItemRow> Items { get; set; } = new();
        public List<ReportePedido360CotizacionRow> Cotizacion { get; set; } = new();
        public List<ReportePedido360PagoRow> Pagos { get; set; } = new();
        public List<ReportePedido360ProduccionRow> Produccion { get; set; } = new();
        public List<ReportePedido360ConsumoRow> Consumo { get; set; } = new();
        public List<ReportePedido360HistoriaRow> Historia { get; set; } = new();
    }
}