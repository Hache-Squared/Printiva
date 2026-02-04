using System;

namespace ManejoPresupuestos.Models
{
    public class ReporteProduccionUtilizacionTotalesDto
    {
        public int Items { get; set; }
        public int ItemsCompletados { get; set; }
        public int ItemsEnCurso { get; set; }
        public int ItemsSinTiempos { get; set; }

        public decimal HorasCompletadas { get; set; }
        public decimal HorasEnCurso { get; set; }
        public decimal HorasTotales { get; set; }

        public decimal AvgDuracionMin { get; set; }

        public int Fallas { get; set; }
        public int Reimpresiones { get; set; }
    }

    public class ReporteProduccionUtilizacionPorImpresoraDto
    {
        public int? ImpresoraId { get; set; }
        public string? ImpresoraNombre { get; set; }
        public string? ImpresoraModelo { get; set; }

        public int Items { get; set; }
        public int ItemsCompletados { get; set; }
        public int ItemsEnCurso { get; set; }
        public int ItemsSinTiempos { get; set; }

        public decimal HorasCompletadas { get; set; }
        public decimal HorasEnCurso { get; set; }
        public decimal HorasTotales { get; set; }

        public decimal AvgDuracionMin { get; set; }

        public int Fallas { get; set; }
        public int Reimpresiones { get; set; }
    }

    public class ReporteProduccionUtilizacionDetalleDto
    {
        public int ProduccionItemId { get; set; }
        public int PedidoId { get; set; }
        public int PedidoItemId { get; set; }

        public int ClienteId { get; set; }
        public string ClienteNombre { get; set; } = "";

        public int ProductoId { get; set; }
        public string ProductoNombre { get; set; } = "";

        public int? ImpresoraId { get; set; }
        public string? ImpresoraNombre { get; set; }
        public string? ImpresoraModelo { get; set; }

        public int ProduccionEstatusId { get; set; }
        public string ProduccionEstatusNombre { get; set; } = "";
        public int ProduccionEstatusOrden { get; set; }
        public string? BadgeClass { get; set; }

        public DateTime? FechaInicio { get; set; }
        public DateTime? FechaFin { get; set; }

        public decimal DuracionMin { get; set; }

        public bool EsCompletado { get; set; }
        public bool EsEnCurso { get; set; }
        public bool SinTiempos { get; set; }

        public bool MarcadaFalla { get; set; }
        public bool EsReimpresion { get; set; }
    }

    public class CatalogoImpresoraDto
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = "";
        public string? Modelo { get; set; }
    }
}