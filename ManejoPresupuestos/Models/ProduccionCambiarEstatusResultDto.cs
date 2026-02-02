namespace ManejoPresupuestos.Models
{
    // Extiende tu result para leer columnas extra del SP (desde/hacia/aplicadoAhora)
    public class ProduccionCambiarEstatusResultDto : ResultProcedureGeneric
    {
        public int? DesdeEstatusId { get; set; }
        public int? HaciaEstatusId { get; set; }
        public bool InventarioAplicadoAhora { get; set; }
    }
}