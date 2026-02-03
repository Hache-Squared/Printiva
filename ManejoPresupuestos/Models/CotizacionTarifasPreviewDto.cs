namespace ManejoPresupuestos.Models
{
    public class CotizacionTarifaPreviewRequestDto
    {
        public int? ImpresoraId { get; set; } // opcional a futuro
        public List<CotizacionTarifaPreviewItemDto> Items { get; set; } = new();
    }

    public class CotizacionTarifaPreviewItemDto
    {
        public int ConceptoTipoId { get; set; }          // 1=Modelado, 2=Producción
        public int ProductoId { get; set; }              // requerido para receta
        public string? ProductoNombre { get; set; }      // opcional (solo para warnings)
        public decimal Cantidad { get; set; }            // cantidad de piezas del producto
    }

    public class CotizacionTarifaPreviewResponseDto
    {
        public string Result { get; set; } = "success";
        public string Message { get; set; } = "OK";

        public decimal TotalTarifas { get; set; }
        public List<TarifaAplicadaDto> Detalle { get; set; } = new();

        // Productos que vienen en cotización pero no tienen receta asignada
        public List<string> ProductosSinReceta { get; set; } = new();
    }

    public class TarifaAplicadaDto
    {
        public int TarifaId { get; set; }

        public string ConceptoCodigo { get; set; } = "";
        public string ConceptoNombre { get; set; } = "";
        public string TarifaNombre { get; set; } = "";
        public string Unidad { get; set; } = "";
        public string Moneda { get; set; } = "MXN";

        public decimal Monto { get; set; }               // costo unitario o flat
        public decimal Cantidad { get; set; }            // qty aplicada (ej: gramos/unidades o 1 si flat)
        public decimal Subtotal { get; set; }

        public bool EsGlobal { get; set; }
        public string AplicaA { get; set; } = "";        // texto para UI (Inventario #, Global, etc.)
    }
}